import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/auth_controller.dart';
import '../../controller/chat_controller.dart';
import 'chat_view_screen.dart';

class DeliveryBoyChatListScreen extends StatelessWidget {
  const DeliveryBoyChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final ChatController chatController = Get.find<ChatController>();

    // Set currentUserId before accessing the stream
    chatController.currentUserId.value = authController.userId;

    if (authController.role != 'delivery') {
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
              onPressed: () {
                _showOrderSelector(context, chatController, authController);
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                Get.snackbar(
                  "Refreshing",
                  "Reloading chats...",
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
        body: StreamBuilder<List<QuerySnapshot>>(
          stream: chatController.getConversations(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.orange)));
            }
            if (snapshot.hasError) {
              FirebaseCrashlytics.instance.recordError(
                  snapshot.error, StackTrace.current,
                  reason: 'Failed to load delivery boy chats');
              bool isIndexError =
                  snapshot.error.toString().contains("FAILED_PRECONDITION");
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.orange, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      isIndexError
                          ? "Chats are being set up. Please wait a few minutes and try again."
                          : "Error loading chats: ${snapshot.error}",
                      style: TextStyle(color: Colors.grey[700], fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Get.forceAppUpdate(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: const Text("Retry",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                    if (isIndexError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "If the issue persists, contact support.",
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14),
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
                    const Icon(Icons.chat_bubble_outline,
                        color: Colors.orange, size: 40),
                    const SizedBox(height: 8),
                    Text("No chats available",
                        style: TextStyle(color: Colors.orange, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text("Use the '+' icon to start a chat with a customer",
                        style: TextStyle(color: Colors.orange, fontSize: 14)),
                  ],
                ),
              );
            }

            final conversations =
                snapshot.data!.expand((qs) => qs.docs).toList();
            // Deduplicate conversations based on conversation.id
            final uniqueConversations = <String, QueryDocumentSnapshot>{};
            for (var convo in conversations) {
              uniqueConversations[convo.id] = convo;
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: uniqueConversations.length,
              itemBuilder: (context, index) {
                final conversation =
                    uniqueConversations.values.elementAt(index);
                final lastMessage =
                    conversation['lastMessage'] ?? 'No messages';
                final timestamp = conversation['lastTimestamp'] as Timestamp?;
                final participants =
                    List<dynamic>.from(conversation['participants'] ?? []);
                final unreadCounts = Map<String, dynamic>.from(
                    conversation['unreadCounts'] ?? {});
                final unreadCount = unreadCounts[authController.userId] ?? 0;

                final otherUserId = participants.firstWhere(
                  (id) => id != authController.userId,
                  orElse: () => 'Unknown',
                );

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(otherUserId)
                      .get(),
                  builder: (context, userSnapshot) {
                    String otherUserName = userSnapshot.hasData
                        ? userSnapshot.data!.get('displayName') ?? 'Unknown'
                        : 'Loading...';
                    String otherUserRole = userSnapshot.hasData
                        ? userSnapshot.data!.get('role') ?? 'Unknown'
                        : 'Loading...';

                    return GestureDetector(
                      onTap: () async {
                        try {
                          if (otherUserRole == 'customer') {
                            final orderSnapshot = await FirebaseFirestore
                                .instance
                                .collection('orders')
                                .where('customerId', isEqualTo: otherUserId)
                                .where('deliveryBoyId',
                                    isEqualTo: authController.userId)
                                .limit(1)
                                .get();

                            if (orderSnapshot.docs.isEmpty) {
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
                          } else if (otherUserRole == 'admin') {
                            await chatController.setAdminDeliveryChatContext(
                                deliveryBoyId: authController.userId);
                          }
                          await chatController.resetUnreadCount(
                              conversation.id, authController.userId);
                          Get.to(() => ChatViewScreen());
                        } catch (e) {
                          FirebaseCrashlytics.instance.recordError(
                              e, StackTrace.current,
                              reason: 'Failed to open delivery boy chat');
                          Get.snackbar('Error', 'Failed to load chat: $e',
                              backgroundColor: Colors.redAccent,
                              colorText: Colors.white);
                        }
                      },
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.orange,
                                child: Text(
                                  otherUserName.isNotEmpty
                                      ? otherUserName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "$otherUserName (${otherUserRole.capitalizeFirst})",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blueGrey[800]),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            lastMessage,
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600]),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (unreadCount > 0)
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              unreadCount.toString(),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    chatController.formatTimestamp(timestamp),
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[500]),
                                  ),
                                  const SizedBox(height: 4),
                                  if (otherUserRole == 'customer')
                                    const Icon(Icons.person,
                                        size: 16, color: Colors.green),
                                  if (otherUserRole == 'admin')
                                    const Icon(Icons.support_agent,
                                        size: 16, color: Colors.blue),
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
}
