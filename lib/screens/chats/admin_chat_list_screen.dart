import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/auth_controller.dart';
import '../../controller/chat_controller.dart';
import '../../controller/user_controller.dart';
import 'chat_view_screen.dart';

class AdminChatListScreen extends StatelessWidget {
  const AdminChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final ChatController chatController = Get.find<ChatController>();
    final UserController userController = Get.find<UserController>();

    if (authController.role != 'admin') {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Access denied: Admins only")),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.orange.shade200],
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.orange,
          title: const Text(
            "Admin Chats",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.add, color: Colors.white),
              onSelected: (value) {
                if (value == 'customer') {
                  _showUserSelector(context, chatController, userController, 'customer');
                } else if (value == 'delivery') {
                  _showUserSelector(context, chatController, userController, 'delivery');
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'customer', child: Text("Chat with Customer")),
                const PopupMenuItem(value: 'delivery', child: Text("Chat with Delivery Boy")),
              ],
            ),
          ],
        ),
        body: StreamBuilder<List<QuerySnapshot>>(
          stream: chatController.getConversations(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              FirebaseCrashlytics.instance.recordError(snapshot.error, StackTrace.current, reason: 'Failed to load admin chats');
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
                          : "Error: ${snapshot.error}",
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
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: Colors.orange, size: 40),
                    const SizedBox(height: 8),
                    const Text("No chats available", style: TextStyle(color: Colors.orange, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text("Use the '+' icon to start a chat", style: TextStyle(color: Colors.orange, fontSize: 14)),
                  ],
                ),
              );
            }

            final conversations = snapshot.data!.expand((qs) => qs.docs).toList();
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                final lastMessage = conversation['lastMessage'] ?? 'No messages';
                final timestamp = conversation['lastTimestamp'] as Timestamp?;
                final participants = List<dynamic>.from(conversation['participants'] ?? []);
                final unreadCounts = Map<String, dynamic>.from(conversation['unreadCounts'] ?? {});
                final unreadCount = unreadCounts[authController.userId] ?? 0;

                final otherUserId = participants.firstWhere(
                      (id) => id != authController.userId,
                  orElse: () => 'Unknown',
                );

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(title: Text('Loading...'));
                    }
                    if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return const ListTile(title: Text('User not found'));
                    }

                    final otherUserName = userSnapshot.data!.get('displayName') ?? 'Unknown';
                    final otherUserRole = userSnapshot.data!.get('role') ?? 'Unknown';

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: unreadCount > 0 ? Colors.white : Colors.grey[50],
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.orange,
                          child: Text(
                            otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                otherUserName,
                                style: TextStyle(
                                  fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                                  color: Colors.blueGrey[800],
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              chatController.formatTimestamp(timestamp),
                              style: TextStyle(fontSize: 12, color: unreadCount > 0 ? Colors.orange : Colors.grey),
                            ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Icon(
                              otherUserRole == 'delivery' ? Icons.delivery_dining : Icons.person,
                              size: 16,
                              color: otherUserRole == 'delivery' ? Colors.blue : Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                lastMessage,
                                style: TextStyle(
                                  fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                                  color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        trailing: unreadCount > 0
                            ? Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        )
                            : null,
                        onTap: () async {
                          try {
                            if (otherUserRole == 'customer') {
                              await chatController.setCustomerAdminChatContext(customerId: otherUserId);
                            } else if (otherUserRole == 'delivery') {
                              await chatController.setAdminDeliveryChatContext(deliveryBoyId: otherUserId);
                            }
                            await chatController.resetUnreadCount(conversation.id, authController.userId);
                            Get.to(() => ChatViewScreen());
                          } catch (e) {
                            FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Failed to open admin chat');
                            Get.snackbar('Error', 'Failed to open chat: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
                          }
                        },
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

  void _showUserSelector(BuildContext context, ChatController chatController, UserController userController, String role) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: role).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text("Error loading users"));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text("No $role users found"));
            }

            final users = snapshot.data!.docs;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Select ${role.capitalizeFirst}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final userId = user.id;
                        final displayName = user['displayName'] ?? 'Unknown';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(displayName),
                          trailing: Icon(
                            role == 'delivery' ? Icons.delivery_dining : Icons.person,
                            color: Colors.orange,
                          ),
                          onTap: () async {
                            try {
                              if (role == 'customer') {
                                await chatController.setCustomerAdminChatContext(customerId: userId);
                              } else {
                                await chatController.setAdminDeliveryChatContext(deliveryBoyId: userId);
                              }
                              await chatController.resetUnreadCount(
                                  chatController.chatType.value == ChatType.order
                                      ? chatController.orderId.value
                                      : chatController.generateConversationId(userId, 'admin'),
                                  'admin');
                              Get.back();
                              Get.to(() => ChatViewScreen());
                            } catch (e) {
                              FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Failed to start chat with $role');
                              Get.snackbar('Error', 'Failed to start chat: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
