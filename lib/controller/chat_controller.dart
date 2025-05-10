import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:food_ui/Chat_System/Classes/user_cache.dart';
import 'package:get/get.dart';
import 'package:rxdart/rxdart.dart' as rxDart;
import '../Chat_System/Classes/constants.dart';
import '../services/notification_services.dart';
import 'auth_controller.dart';

enum ChatType { customerAdmin, order, adminDelivery }

class ChatController extends GetxController {
  var currentUserId = ''.obs;
  var chatType = Rxn<ChatType>();
  var customerId = ''.obs;
  var orderId = ''.obs;
  var deliveryBoyId = ''.obs;
  var recipientName = ''.obs;
  var adminId = ''.obs;
  var isSending = false.obs;
  final messageController = TextEditingController();
  final scrollController = ScrollController();

  @override
  void onInit() async {
    super.onInit();
    await UserCache.init();
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    AwesomeNotificationService.init();
    // Set currentUserId from AuthController
    final authController = Get.find<AuthController>();
    if (authController.userId.isNotEmpty) {
      currentUserId.value = authController.userId;
    }
    // Listen for auth changes
    ever(authController.firebaseUser, (User? user) {
      if (user != null && user.uid.isNotEmpty) {
        currentUserId.value = user.uid;
      } else {
        currentUserId.value = '';
      }
    });
    await _loadAdminId();
  }

  Future<void> _loadAdminId() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection(Constants.usersCollection)
          .where('role', isEqualTo: Constants.adminRole)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        adminId.value = query.docs.first.id;
        await UserCache.cacheUser(adminId.value, query.docs.first.data());
      } else {
        FirebaseCrashlytics.instance.recordError(
            Exception('No admin user found in users collection'),
            StackTrace.current,
            reason: 'Failed to preload admin ID: Empty query result');
        print('Error: No admin user found in users collection');
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to preload admin ID: $e');
      print('Error loading admin ID: $e');
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
      final conversationId = chatType == ChatType.order
          ? orderId!
          : generateConversationId(participant1Id, participant2Id);
      final collection = chatType == ChatType.order
          ? Constants.chatsCollection
          : Constants.conversationsCollection;
      final conversationRef =
      FirebaseFirestore.instance.collection(collection).doc(conversationId);
      final doc = await conversationRef.get();
      if (doc.exists) return;

      final user1Doc = await FirebaseFirestore.instance
          .collection(Constants.usersCollection)
          .doc(participant1Id)
          .get();
      final user2Doc = await FirebaseFirestore.instance
          .collection(Constants.usersCollection)
          .doc(participant2Id)
          .get();
      if (!user1Doc.exists || !user2Doc.exists) {
        throw Exception('One or both participants do not exist');
      }

      final participants = [participant1Id, participant2Id];
      final data = {
        'participants': participants,
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
        'chatType': chatType.toString().split('.').last,
        'unreadCounts': {participant1Id: 0, participant2Id: 0},
      };
      await conversationRef.set(data, SetOptions(merge: true));

      final senderName = user1Doc.get('displayName') ?? 'User';
      await AwesomeNotificationService.showNotification(
        title: 'New Chat Started',
        body:
        '$senderName started a ${chatType.toString().split('.').last} chat${chatType == ChatType.order ? ' for order #$orderId' : ''}.',
      );
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to create conversation');
      Get.snackbar('Error', 'Failed to create conversation: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      throw e;
    }
  }

  Future<void> setChatDetails({
    required String conversationId,
    required String otherParticipantId,
    required String otherUserRole,
    required ChatType chatType,
  }) async {
    try {
      // Set chat type and current user ID
      this.chatType.value = chatType;
      currentUserId.value = Get.find<AuthController>().userId;

      // Validate current user ID
      if (currentUserId.value.isEmpty) {
        throw Exception('Current user ID is empty');
      }

      // Set participant IDs based on chat type
      if (chatType == ChatType.order) {
        orderId.value = conversationId;
        // Fetch participants from Firestore to determine customerId and deliveryBoyId
        final convoDoc = await FirebaseFirestore.instance
            .collection(Constants.chatsCollection)
            .doc(conversationId)
            .get();
        if (!convoDoc.exists) {
          throw Exception('Chat document does not exist for order #$conversationId');
        }
        final participants = List<String>.from(convoDoc.get('participants') ?? []);
        if (participants.length != 2) {
          throw Exception('Invalid participants for order chat');
        }
        customerId.value = participants.firstWhere(
              (id) => id != otherParticipantId,
          orElse: () => '',
        );
        deliveryBoyId.value = otherParticipantId;
      } else if (chatType == ChatType.customerAdmin) {
        customerId.value = currentUserId.value == adminId.value ? otherParticipantId : currentUserId.value;
        adminId.value = currentUserId.value == adminId.value ? currentUserId.value : otherParticipantId;
      } else if (chatType == ChatType.adminDelivery) {
        deliveryBoyId.value = currentUserId.value == adminId.value ? otherParticipantId : currentUserId.value;
        adminId.value = currentUserId.value == adminId.value ? currentUserId.value : otherParticipantId;
      }

      // Fetch and set recipientName for the other participant
      final userDoc = await FirebaseFirestore.instance
          .collection(Constants.usersCollection)
          .doc(otherParticipantId)
          .get();
      recipientName.value = userDoc.exists
          ? userDoc.get('displayName') ?? 'User'
          : 'User';
      await UserCache.cacheUser(otherParticipantId, userDoc.data() ?? {});
      print('Set recipientName to ${recipientName.value} for otherParticipantId: $otherParticipantId, chatType: $chatType');

      // Ensure conversation exists
      await createConversation(
        participant1Id: chatType == ChatType.order ? customerId.value : adminId.value,
        participant2Id: chatType == ChatType.order ? deliveryBoyId.value : otherParticipantId,
        chatType: chatType,
        orderId: chatType == ChatType.order ? orderId.value : null,
      );

      // Reset unread count for the current user
      await resetUnreadCount(conversationId, currentUserId.value);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to set chat details: $e');
      Get.snackbar('Error', 'Failed to initialize chat: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      throw e;
    }
  }

  Future<void> setCustomerAdminChatContext({required String customerId}) async {
    try {
      if (adminId.value.isEmpty) {
        await _loadAdminId();
        if (adminId.value.isEmpty) {
          throw Exception('Admin ID not found. Please ensure an admin user exists.');
        }
      }
      final otherParticipantId = Get.find<AuthController>().userId == customerId ? adminId.value : customerId;
      await setChatDetails(
        conversationId: generateConversationId(customerId, adminId.value),
        otherParticipantId: otherParticipantId,
        otherUserRole: otherParticipantId == adminId.value ? 'admin' : 'customer',
        chatType: ChatType.customerAdmin,
      );
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to set customer-admin chat context: $e');
      Get.snackbar('Error', 'Failed to initialize chat: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      throw e;
    }
  }

  Future<void> setOrderChatContext({
    required String orderId,
    required String customerId,
    required String deliveryBoyId,
  }) async {
    try {
      final otherParticipantId = Get.find<AuthController>().userId == customerId ? deliveryBoyId : customerId;
      await setChatDetails(
        conversationId: orderId,
        otherParticipantId: otherParticipantId,
        otherUserRole: otherParticipantId == deliveryBoyId ? 'delivery' : 'customer',
        chatType: ChatType.order,
      );
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to set order chat context: $e');
      Get.snackbar('Error', 'Failed to initialize chat: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      throw e;
    }
  }

  Future<void> setAdminDeliveryChatContext({required String deliveryBoyId}) async {
    try {
      if (adminId.value.isEmpty) {
        await _loadAdminId();
        if (adminId.value.isEmpty) {
          throw Exception('Admin ID not found. Please ensure an admin user exists.');
        }
      }
      final otherParticipantId = Get.find<AuthController>().userId == deliveryBoyId ? adminId.value : deliveryBoyId;
      await setChatDetails(
        conversationId: generateConversationId(adminId.value, deliveryBoyId),
        otherParticipantId: otherParticipantId,
        otherUserRole: otherParticipantId == adminId.value ? 'admin' : 'delivery',
        chatType: ChatType.adminDelivery,
      );
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to set admin-delivery chat context: $e');
      Get.snackbar('Error', 'Failed to initialize chat: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      throw e;
    }
  }

  Stream<List<QuerySnapshot<Object?>>> getConversations() {
    try {
      if (currentUserId.value.isEmpty) {
        return Stream.value([]);
      }
      final conversationsStream = FirebaseFirestore.instance
          .collection(Constants.conversationsCollection)
          .where('participants', arrayContains: currentUserId.value)
          .orderBy('lastTimestamp', descending: true)
          .snapshots();
      final chatsStream = FirebaseFirestore.instance
          .collection(Constants.chatsCollection)
          .where('participants', arrayContains: currentUserId.value)
          .orderBy('lastTimestamp', descending: true)
          .snapshots();
      return rxDart.CombineLatestStream.combine2(
        conversationsStream,
        chatsStream,
            (QuerySnapshot<Object?> convos, QuerySnapshot<Object?> chats) => [convos, chats],
      ).debounceTime(const Duration(milliseconds: 300));
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to get conversations stream');
      Get.snackbar('Error', 'Failed to load conversations: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return Stream.value([]);
    }
  }

  Stream<QuerySnapshot<Object?>> getChatStream() {
    try {
      if (chatType.value == null || currentUserId.value.isEmpty) {
        Get.snackbar('Error', 'Chat context not set',
            backgroundColor: Colors.redAccent, colorText: Colors.white);
        return Stream.empty();
      }
      final collection = chatType.value == ChatType.order
          ? Constants.chatsCollection
          : Constants.conversationsCollection;
      final docId = chatType.value == ChatType.order
          ? orderId.value
          : generateConversationId(
        chatType.value == ChatType.customerAdmin ? customerId.value : adminId.value,
        chatType.value == ChatType.customerAdmin ? adminId.value : deliveryBoyId.value,
      );
      return FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots();
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to get chat stream');
      Get.snackbar('Error', 'Failed to load messages: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return Stream.empty();
    }
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty || isSending.value) return;
    isSending.value = true;
    try {
      final messageText = messageController.text.trim();
      final collection = chatType.value == ChatType.order
          ? Constants.chatsCollection
          : Constants.conversationsCollection;
      final docId = chatType.value == ChatType.order
          ? orderId.value
          : generateConversationId(
        chatType.value == ChatType.customerAdmin ? customerId.value : adminId.value,
        chatType.value == ChatType.customerAdmin ? adminId.value : deliveryBoyId.value,
      );
      final conversationRef = FirebaseFirestore.instance.collection(collection).doc(docId);
      final receiverId = chatType.value == ChatType.order
          ? (currentUserId.value == customerId.value ? deliveryBoyId.value : customerId.value)
          : (chatType.value == ChatType.customerAdmin
          ? (currentUserId.value == customerId.value ? adminId.value : customerId.value)
          : (currentUserId.value == deliveryBoyId.value ? adminId.value : deliveryBoyId.value));

      final senderDoc = await FirebaseFirestore.instance
          .collection(Constants.usersCollection)
          .doc(currentUserId.value)
          .get();
      final senderName = senderDoc.exists ? senderDoc.get('displayName') ?? 'User' : 'User';

      await conversationRef.set({
        'lastMessage': messageText,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'unreadCounts': {receiverId: FieldValue.increment(1)},
      }, SetOptions(merge: true));

      await conversationRef.collection('messages').add({
        'senderId': currentUserId.value,
        'receiverId': receiverId,
        'message': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [currentUserId.value],
      });

      final lastTimestamp = (await conversationRef.get()).data()?['lastTimestamp'] as Timestamp?;
      if (lastTimestamp == null || DateTime.now().difference(lastTimestamp.toDate()).inMinutes > 5) {
        await AwesomeNotificationService.showNotification(
          title: 'New Message from $senderName',
          body: chatType.value == ChatType.order
              ? 'Order #${orderId.value}: $messageText'
              : '$messageText',
        );
      }

      messageController.clear();
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Failed to send message');
      Get.snackbar('Error', 'Failed to send message: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isSending.value = false;
    }
  }

  Future<void> resetUnreadCount(String conversationId, String userId) async {
    try {
      final chatRef = FirebaseFirestore.instance.collection(Constants.chatsCollection).doc(conversationId);
      final convoRef = FirebaseFirestore.instance.collection(Constants.conversationsCollection).doc(conversationId);
      DocumentSnapshot? docSnapshot;
      String collection;

      docSnapshot = await chatRef.get();
      if (docSnapshot.exists) {
        collection = Constants.chatsCollection;
      } else {
        docSnapshot = await convoRef.get();
        collection = Constants.conversationsCollection;
      }

      if (docSnapshot.exists) {
        await FirebaseFirestore.instance.collection(collection).doc(conversationId).update({
          'unreadCounts.$userId': 0,
        });

        final messages = await FirebaseFirestore.instance
            .collection(collection)
            .doc(conversationId)
            .collection('messages')
            .where('readBy', arrayContains: userId)
            .get();
        for (var message in messages.docs) {
          await message.reference.update({
            'readBy': FieldValue.arrayUnion([userId]),
          });
        }
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Failed to reset unread count');
      if (e.toString().contains('NOT_FOUND')) return;
      rethrow;
    }
  }

  Future<void> clearChat(String conversationId, String collection) async {
    try {
      final messagesRef = FirebaseFirestore.instance.collection(collection).doc(conversationId).collection('messages');
      final messages = await messagesRef.get();
      for (var message in messages.docs) {
        await message.reference.delete();
      }
      await FirebaseFirestore.instance.collection(collection).doc(conversationId).update({
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
        'unreadCounts': {currentUserId.value: 0},
      });
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Failed to clear chat');
      rethrow;
    }
  }

  Future<void> deleteChat(String conversationId, String collection) async {
    try {
      final messagesRef = FirebaseFirestore.instance.collection(collection).doc(conversationId).collection('messages');
      final messages = await messagesRef.get();
      for (var message in messages.docs) {
        await message.reference.delete();
      }
      await FirebaseFirestore.instance.collection(collection).doc(conversationId).delete();
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Failed to delete chat');
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
