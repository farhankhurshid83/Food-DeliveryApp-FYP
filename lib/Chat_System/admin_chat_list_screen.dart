import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/auth_controller.dart';
import '../../controller/chat_controller.dart';
import '../../controller/user_controller.dart';
import 'Classes/chat_list_widget.dart';
import 'Classes/constants.dart';
import 'chat_view_screen.dart';

class AdminChatListScreen extends StatelessWidget {
  const AdminChatListScreen({super.key});

  void _showUserSelector(BuildContext context, ChatController chatController,
      UserController userController, String role) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: role)
              .snapshots(),
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
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
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
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(displayName),
                          trailing: Icon(
                            role == Constants.deliveryRole
                                ? Icons.delivery_dining
                                : Icons.person,
                            color: Colors.orange,
                          ),
                          onTap: () async {
                            Get.dialog(
                                const Center(
                                    child: CircularProgressIndicator()),
                                barrierDismissible: false);
                            try {
                              if (role == Constants.customerRole) {
                                await chatController
                                    .setCustomerAdminChatContext(
                                        customerId: userId);
                              } else {
                                await chatController
                                    .setAdminDeliveryChatContext(
                                        deliveryBoyId: userId);
                              }
                              await chatController.resetUnreadCount(
                                  chatController.chatType.value ==
                                          ChatType.order
                                      ? chatController.orderId.value
                                      : chatController.generateConversationId(
                                          userId, chatController.adminId.value),
                                  chatController.adminId.value);
                              Get.back();
                              Get.to(() => ChatViewScreen());
                            } catch (e) {
                              FirebaseCrashlytics.instance.recordError(
                                  e, StackTrace.current,
                                  reason: 'Failed to start chat with $role');
                              Get.back();
                              Get.snackbar('Error', 'Failed to start chat: $e',
                                  backgroundColor: Colors.redAccent,
                                  colorText: Colors.white);
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

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final ChatController chatController = Get.find<ChatController>();
    final UserController userController = Get.find<UserController>();

    if (authController.role.value != Constants.adminRole) {
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
                if (value == Constants.customerRole) {
                  _showUserSelector(context, chatController, userController,
                      Constants.customerRole);
                } else if (value == Constants.deliveryRole) {
                  _showUserSelector(context, chatController, userController,
                      Constants.deliveryRole);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                    value: Constants.customerRole,
                    child: Text("Chat with Customer")),
                PopupMenuItem(
                    value: Constants.deliveryRole,
                    child: Text("Chat with Delivery Boy")),
              ],
            ),
          ],
        ),
        body: ChatListWidget(
          conversationsStream: chatController.getConversations(),
          userId: authController.userId,
          role: authController.role.value,
          onChatTap: (conversationId, otherUserId, otherUserRole) async {
            Get.dialog(const Center(child: CircularProgressIndicator()),
                barrierDismissible: false);
            try {
              if (otherUserRole == Constants.customerRole) {
                await chatController.setCustomerAdminChatContext(
                    customerId: otherUserId);
              } else if (otherUserRole == Constants.deliveryRole) {
                await chatController.setAdminDeliveryChatContext(
                    deliveryBoyId: otherUserId);
              }
              await chatController.resetUnreadCount(
                  conversationId, authController.userId);
              Get.back();
              Get.to(() => ChatViewScreen());
            } catch (e) {
              FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
                  reason: 'Failed to open admin chat');
              Get.back();
              Get.snackbar('Error', 'Failed to open chat: $e',
                  backgroundColor: Colors.redAccent, colorText: Colors.white);
            }
          },
        ),
      ),
    );
  }
}
