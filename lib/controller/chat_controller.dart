import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rxdart/rxdart.dart';
import 'auth_controller.dart';

enum ChatType { customerAdmin, order, adminDelivery }

class ChatController extends GetxController {
  var currentUserId = ''.obs;
  var chatType = Rxn<ChatType>();
  var customerId = ''.obs;
  var orderId = ''.obs;
  var deliveryBoyId = ''.obs;
  var recipientName = ''.obs;
  final messageController = TextEditingController();
  final scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  }

  Future<String> getAdminId() async {
    try {
      var query = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        throw Exception('No admin user found');
      }
      return query.docs.first.id;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Failed to fetch admin ID');
      Get.snackbar('Error', 'Failed to find admin: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
      rethrow;
    }
  }

  String generateConversationId(String user1Id, String user2Id) {
    final ids = [user1Id, user2Id]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> createConversation({
    required String participant1Id,
    required String participant2Id,
    required ChatType chatType,
    String? orderId,
  }) async {
    try {
      // Validate participants
      final user1Doc = await FirebaseFirestore.instance.collection('users').doc(participant1Id).get();
      final user2Doc = await FirebaseFirestore.instance.collection('users').doc(participant2Id).get();
      if (!user1Doc.exists || !user2Doc.exists) {
        throw Exception('One or both participants do not exist');
      }

      final conversationId = chatType == ChatType.order
          ? orderId!
          : generateConversationId(participant1Id, participant2Id);
      final collection = chatType == ChatType.order ? 'chats' : 'conversations';
      final conversationRef = FirebaseFirestore.instance.collection(collection).doc(conversationId);

      final participants = [participant1Id, participant2Id];
      final data = {
        'participants': participants,
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
        'chatType': chatType.toString().split('.').last,
        'unreadCounts': {participant1Id: 0, participant2Id: 0},
      };
      await conversationRef.set(data, SetOptions(merge: true));
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Failed to create conversation');
      Get.snackbar('Error', 'Failed to create conversation: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
      throw e;
    }
  }

  Future<void> setCustomerAdminChatContext({required String customerId}) async {
    try {
      final adminId = await getAdminId();
      this.customerId.value = customerId;
      currentUserId.value = Get.find<AuthController>().userId;
      chatType.value = ChatType.customerAdmin;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(customerId).get();
      recipientName.value = userDoc.exists ? userDoc.get('displayName') ?? 'Customer' : 'Customer';
      await createConversation(
        participant1Id: customerId,
        participant2Id: adminId,
        chatType: ChatType.customerAdmin,
      );
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Failed to set customer-admin chat context');
      Get.snackbar('Error', 'Failed to initialize chat: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> setOrderChatContext({
    required String orderId,
    required String customerId,
    required String deliveryBoyId,
  }) async {
    try {
      this.orderId.value = orderId;
      this.customerId.value = customerId;
      this.deliveryBoyId.value = deliveryBoyId;
      currentUserId.value = Get.find<AuthController>().userId;
      chatType.value = ChatType.order;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId.value == customerId ? deliveryBoyId : customerId)
          .get();
      recipientName.value = userDoc.exists ? userDoc.get('displayName') ?? 'User' : 'User';
      await createConversation(
        participant1Id: customerId,
        participant2Id: deliveryBoyId,
        chatType: ChatType.order,
        orderId: orderId,
      );
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Failed to set order chat context');
      Get.snackbar('Error', 'Failed to initialize chat: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> setAdminDeliveryChatContext({required String deliveryBoyId}) async {
    try {
      final adminId = await getAdminId();
      this.deliveryBoyId.value = deliveryBoyId;
      currentUserId.value = Get.find<AuthController>().userId;
      chatType.value = ChatType.adminDelivery;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(deliveryBoyId).get();
      recipientName.value = userDoc.exists ? userDoc.get('displayName') ?? 'Delivery' : 'Delivery';
      await createConversation(
        participant1Id: adminId,
        participant2Id: deliveryBoyId,
        chatType: ChatType.adminDelivery,
      );
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Failed to set admin-delivery chat context');
      Get.snackbar('Error', 'Failed to initialize chat: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Stream<List<QuerySnapshot>> getConversations() {
    try {
      final conversationsStream = FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: currentUserId.value)
          .orderBy('lastTimestamp', descending: true)
          .snapshots();

      final chatsStream = FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserId.value)
          .orderBy('lastTimestamp', descending: true)
          .snapshots();

      return CombineLatestStream.list([conversationsStream, chatsStream]);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Failed to get conversations stream');
      Get.snackbar('Error', 'Failed to load conversations: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return Stream.value([]);
    }
  }

  Stream<QuerySnapshot> getChatStream() {
    try {
      if (chatType.value == null || currentUserId.value.isEmpty) {
        Get.snackbar('Error', 'Chat context not set', backgroundColor: Colors.redAccent, colorText: Colors.white);
        return Stream.empty();
      }
      final collection = chatType.value == ChatType.order ? 'chats' : 'conversations';
      final docId = chatType.value == ChatType.order
          ? orderId.value
          : generateConversationId(
        chatType.value == ChatType.customerAdmin ? customerId.value : 'admin',
        chatType.value == ChatType.customerAdmin ? 'admin' : deliveryBoyId.value,
      );
      return FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots();
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Failed to get chat stream');
      Get.snackbar('Error', 'Failed to load messages: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return Stream.empty();
    }
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;
    try {
      final messageText = messageController.text.trim();
      final collection = chatType.value == ChatType.order ? 'chats' : 'conversations';
      final docId = chatType.value == ChatType.order
          ? orderId.value
          : generateConversationId(
        chatType.value == ChatType.customerAdmin ? customerId.value : 'admin',
        chatType.value == ChatType.customerAdmin ? 'admin' : deliveryBoyId.value,
      );
      final conversationRef = FirebaseFirestore.instance.collection(collection).doc(docId);
      final receiverId = chatType.value == ChatType.order
          ? (currentUserId.value == customerId.value ? deliveryBoyId.value : customerId.value)
          : (chatType.value == ChatType.customerAdmin
          ? (currentUserId.value == customerId.value ? 'admin' : customerId.value)
          : (currentUserId.value == deliveryBoyId.value ? 'admin' : deliveryBoyId.value));

      // Check for recent duplicate messages (optional)
      final recentMessages = await conversationRef.collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      if (recentMessages.docs.isNotEmpty && recentMessages.docs.first['message'] == messageText) {
        Get.snackbar('Warning', 'Duplicate message detected', backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }

      // Update conversation metadata
      await conversationRef.set({
        'lastMessage': messageText,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'unreadCounts': {receiverId: FieldValue.increment(1)},
      }, SetOptions(merge: true));

      // Add message
      await conversationRef.collection('messages').add({
        'senderId': currentUserId.value,
        'receiverId': receiverId,
        'message': messageText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      messageController.clear();
      scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Failed to send message');
      Get.snackbar('Error', 'Failed to send message: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> resetUnreadCount(String conversationId, String userId) async {
    try {
      // Check both collections to find the document
      final chatRef = FirebaseFirestore.instance.collection('chats').doc(conversationId);
      final convoRef = FirebaseFirestore.instance.collection('conversations').doc(conversationId);

      DocumentSnapshot? docSnapshot;
      String collection;

      // Try 'chats' collection first
      docSnapshot = await chatRef.get();
      if (docSnapshot.exists) {
        collection = 'chats';
      } else {
        // If not found in 'chats', try 'conversations'
        docSnapshot = await convoRef.get();
        collection = 'conversations';
      }

      if (docSnapshot.exists) {
        await FirebaseFirestore.instance.collection(collection).doc(conversationId).update({
          'unreadCounts.$userId': 0,
        });
      } else {
        // Log the missing document but don't throw an error
        FirebaseCrashlytics.instance.recordError(
          Exception('Conversation document not found: $conversationId'),
          StackTrace.current,
          reason: 'Failed to reset unread count - document not found',
        );
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Failed to reset unread count');
      // Only rethrow for non-NOT_FOUND errors if needed
      if (e.toString().contains('NOT_FOUND')) return;
      rethrow;
    }
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
