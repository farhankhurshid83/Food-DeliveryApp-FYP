import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/auth_controller.dart';
import '../../controller/chat_controller.dart';
import 'Classes/chat_list_widget.dart';
import 'Classes/constants.dart';
import 'chat_view_screen.dart';

class DeliveryBoyChatListScreen extends StatelessWidget {
  const DeliveryBoyChatListScreen({super.key});

  void _showOrderSelector(BuildContext context, ChatController chatController,
      AuthController authController) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('deliveryBoyId', isEqualTo: authController.userId)
                .where('status', whereIn: [
              'Pending',
              'Accepted',
              'In Progress',
              'On The Way'
            ]).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.orange)));
              }
              if (snapshot.hasError) {
                return const Center(
                    child: Text("Error loading orders",
                        style: TextStyle(color: Colors.grey)));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text("No active orders found",
                        style: TextStyle(color: Colors.grey)));
              }

              final orders = snapshot.data!.docs;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Select Order to Chat",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final orderId = order.id;
                          final customerId = order['customerId'];

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(customerId)
                                .get(),
                            builder: (context, userSnapshot) {
                              String customerName = userSnapshot.hasData
                                  ? userSnapshot.data!.get('displayName') ??
                                      'Unknown'
                                  : 'Loading...';

                              return ListTile(
                                leading: const Icon(Icons.person,
                                    color: Colors.orange),
                                title: Text("Order #$orderId",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text("Customer: $customerName",
                                    style: TextStyle(color: Colors.grey[600])),
                                onTap: () async {
                                  Get.dialog(
                                      const Center(
                                          child: CircularProgressIndicator()),
                                      barrierDismissible: false);
                                  try {
                                    await chatController.setOrderChatContext(
                                      orderId: orderId,
                                      customerId: customerId,
                                      deliveryBoyId: authController.userId,
                                    );
                                    await chatController.resetUnreadCount(
                                        orderId, authController.userId);
                                    Get.back();
                                    Get.to(() => ChatViewScreen());
                                  } catch (e) {
                                    Get.back();
                                    Get.snackbar(
                                        'Error', 'Failed to start chat: $e',
                                        backgroundColor: Colors.redAccent,
                                        colorText: Colors.white);
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final ChatController chatController = Get.find<ChatController>();

    chatController.currentUserId.value = authController.userId;

    if (authController.role.value != Constants.deliveryRole) {
      return Scaffold(
        appBar: AppBar(
          flexibleSpace:
              Container(decoration: const BoxDecoration(color: Colors.orange)),
          title: const Text("Error", style: TextStyle(color: Colors.white)),
        ),
        body: const Center(child: Text("Access denied: Delivery Boys only")),
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
          flexibleSpace:
              Container(decoration: const BoxDecoration(color: Colors.orange)),
          title: const Text("Delivery Chats",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () =>
                  _showOrderSelector(context, chatController, authController),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                Get.snackbar(
                  "Refreshing",
                  "Reloading Chat_System...",
                  duration: const Duration(seconds: 1),
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.blueGrey,
                  colorText: Colors.white,
                );
                Get.forceAppUpdate();
              },
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
                final orderSnapshot = await FirebaseFirestore.instance
                    .collection('orders')
                    .where('customerId', isEqualTo: otherUserId)
                    .where('deliveryBoyId', isEqualTo: authController.userId)
                    .limit(1)
                    .get();

                if (orderSnapshot.docs.isEmpty) {
                  Get.back();
                  Get.snackbar(
                    'Error',
                    'No active order found for this customer',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.redAccent,
                    colorText: Colors.white,
                  );
                  return;
                }

                final orderId = orderSnapshot.docs.first.id;
                await chatController.setOrderChatContext(
                  orderId: orderId,
                  customerId: otherUserId,
                  deliveryBoyId: authController.userId,
                );
              } else if (otherUserRole == Constants.adminRole) {
                await chatController.setAdminDeliveryChatContext(
                    deliveryBoyId: authController.userId);
              }
              await chatController.resetUnreadCount(
                  conversationId, authController.userId);
              Get.back();
              Get.to(() => ChatViewScreen());
            } catch (e) {
              FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
                  reason: 'Failed to open delivery boy chat');
              Get.back();
              Get.snackbar('Error', 'Failed to load chat: $e',
                  backgroundColor: Colors.redAccent, colorText: Colors.white);
            }
          },
        ),
      ),
    );
  }
}
