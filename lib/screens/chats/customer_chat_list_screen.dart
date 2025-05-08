import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controller/auth_controller.dart';
import '../../controller/chat_controller.dart';
import '../orders_page.dart';
import 'chat_view_screen.dart';

class CustomerChatListScreen extends StatelessWidget {
  const CustomerChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final ChatController chatController = Get.find<ChatController>();

    if (authController.role != 'customer') {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Access denied: Customers only")),
      );
    }

    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          flexibleSpace: Container(color: Colors.orange),
          title: Text(
            'Support Chat',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                Get.to(() => OrdersPage());
                Get.snackbar(
                  "Start Chat",
                  "Select an order to chat with Support or Delivery",
                  duration: const Duration(seconds: 2),
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: const Color(0xFFE85D24),
                  colorText: Colors.white,
                );
              },
            ),
          ],
        ),
        body: StreamBuilder<List<QuerySnapshot>>(
          stream: chatController.getConversations(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE85D24))));
            }
            if (snapshot.hasError) {
              FirebaseCrashlytics.instance.recordError(snapshot.error, StackTrace.current, reason: 'Failed to load customer chats');
              bool isIndexError = snapshot.error.toString().contains("failed-precondition");
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.orange, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      isIndexError
                          ? "Chats are being set up. Please wait a few minutes and try again."
                          : "Error loading chats: ${snapshot.error}",
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => Get.forceAppUpdate(),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: const Text("Retry", style: TextStyle(color: Colors.white)),
                    ),
                    if (isIndexError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "If the issue persists, contact support.",
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline, color: Colors.orange, size: 40),
                    SizedBox(height: 8),
                    Text("No chats available", style: TextStyle(color: Colors.orange, fontSize: 16)),
                    SizedBox(height: 8),
                    Text("Start a chat from the Orders page", style: TextStyle(color: Colors.orange, fontSize: 14)),
                  ],
                ),
              );
            }

            final conversations = snapshot.data!.expand((qs) => qs.docs).toList();
            // Deduplicate based on conversation.id
            final uniqueConversations = <String, QueryDocumentSnapshot>{};
            for (var convo in conversations) {
              uniqueConversations[convo.id] = convo;
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: uniqueConversations.length,
              itemBuilder: (context, index) {
                final conversation = uniqueConversations.values.elementAt(index);
                final lastMessage = conversation['lastMessage'] ?? 'No messages';
                final timestamp = conversation['lastTimestamp'] as Timestamp?;
                final participants = List<dynamic>.from(conversation['participants'] ?? []);

                if (participants.length < 2) {
                  FirebaseCrashlytics.instance.recordError(
                    Exception('Invalid participants list in conversation'),
                    StackTrace.current,
                    reason: 'Conversation ID: ${conversation.id}, Participants: $participants',
                  );
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: const ListTile(
                      leading: CircleAvatar(child: Text('?')),
                      title: Text('Invalid Conversation'),
                      subtitle: Text('Cannot load user data'),
                    ),
                  );
                }

                final otherUserId = participants.firstWhere(
                      (id) => id != authController.userId,
                  orElse: () => 'Unknown',
                );

                if (otherUserId == 'Unknown') {
                  FirebaseCrashlytics.instance.recordError(
                    Exception('Invalid otherUserId in conversation'),
                    StackTrace.current,
                    reason: 'Conversation ID: ${conversation.id}, Participants: $participants',
                  );
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: const ListTile(
                      leading: CircleAvatar(child: Text('?')),
                      title: Text('Invalid Conversation'),
                      subtitle: Text('Cannot load user data'),
                    ),
                  );
                }

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        leading: CircleAvatar(child: Text('?')),
                        title: Text('Loading...'),
                        subtitle: Text('Loading...'),
                      );
                    }
                    if (userSnapshot.hasError) {
                      FirebaseCrashlytics.instance.recordError(
                        userSnapshot.error,
                        StackTrace.current,
                        reason: 'Failed to fetch user data for ID: $otherUserId',
                      );
                      return const ListTile(
                        leading: CircleAvatar(child: Text('?')),
                        title: Text('Error loading user'),
                        subtitle: Text('Try again later'),
                      );
                    }

                    String otherUserName = 'Unknown';
                    String otherUserRole = 'Unknown';

                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      otherUserName = userSnapshot.data!.get('displayName') ?? 'Unknown';
                      otherUserRole = userSnapshot.data!.get('role') ?? 'Unknown';
                    } else {
                      FirebaseCrashlytics.instance.recordError(
                        Exception('User document does not exist for ID: $otherUserId'),
                        StackTrace.current,
                        reason: 'Conversation ID: ${conversation.id}, Participants: $participants',
                      );
                    }

                    return GestureDetector(
                      onTap: () async {
                        try {
                          if (otherUserRole == 'admin') {
                            await chatController.setCustomerAdminChatContext(customerId: authController.userId);
                          } else if (otherUserRole == 'delivery') {
                            final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(conversation.id).get();
                            if (chatDoc.exists) {
                              await chatController.setOrderChatContext(
                                orderId: conversation.id,
                                customerId: authController.userId,
                                deliveryBoyId: otherUserId,
                              );
                            } else {
                              Get.snackbar(
                                'Error',
                                'Order chat not found',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.redAccent,
                                colorText: Colors.white,
                              );
                              return;
                            }
                          } else {
                            Get.snackbar(
                              'Error',
                              'Cannot start chat with unknown user role',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.redAccent,
                              colorText: Colors.white,
                            );
                            return;
                          }
                          await chatController.resetUnreadCount(conversation.id, authController.userId);
                          Get.to(() => ChatViewScreen());
                        } catch (e) {
                          FirebaseCrashlytics.instance.recordError(
                            e,
                            StackTrace.current,
                            reason: 'Failed to load chat in CustomerChatListScreen',
                          );
                          Get.snackbar('Error', 'Failed to load chat: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
                        }
                      },
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.orange,
                                child: Icon(
                                  otherUserRole == 'delivery' ? Icons.delivery_dining : Icons.support_agent,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "$otherUserName (${otherUserRole.capitalizeFirst})",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueGrey[800]),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      lastMessage,
                                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (timestamp != null)
                                    Text(
                                      chatController.formatTimestamp(timestamp),
                                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                    ),
                                  const SizedBox(height: 4),
                                  Icon(
                                    otherUserRole == 'delivery' ? Icons.delivery_dining : Icons.support_agent,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
