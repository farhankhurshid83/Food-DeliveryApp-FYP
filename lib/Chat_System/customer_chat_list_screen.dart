import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:food_ui/screens/Order_Screen/orders_page.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controller/auth_controller.dart';
import '../../controller/chat_controller.dart';
import 'Classes/chat_list_widget.dart';
import 'Classes/constants.dart';
import 'chat_view_screen.dart';

class CustomerChatListScreen extends StatelessWidget {
  const CustomerChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final ChatController chatController = Get.find<ChatController>();

    if (authController.role.value != Constants.customerRole) {
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
            style: GoogleFonts.poppins(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
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
        body: ChatListWidget(
          conversationsStream: chatController.getConversations(),
          userId: authController.userId,
          role: authController.role.value,
          onChatTap: (conversationId, otherUserId, otherUserRole) async {
            Get.dialog(const Center(child: CircularProgressIndicator()),
                barrierDismissible: false);
            try {
              if (otherUserRole == Constants.adminRole) {
                await chatController.setCustomerAdminChatContext(
                    customerId: authController.userId);
              } else if (otherUserRole == Constants.deliveryRole) {
                final chatDoc = await FirebaseFirestore.instance
                    .collection('Chat_System')
                    .doc(conversationId)
                    .get();
                if (chatDoc.exists) {
                  await chatController.setOrderChatContext(
                    orderId: conversationId,
                    customerId: authController.userId,
                    deliveryBoyId: otherUserId,
                  );
                } else {
                  Get.back();
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
                Get.back();
                Get.snackbar(
                  'Error',
                  'Cannot start chat with unknown user role',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.redAccent,
                  colorText: Colors.white,
                );
                return;
              }
              await chatController.resetUnreadCount(
                  conversationId, authController.userId);
              Get.back();
              Get.to(() => ChatViewScreen());
            } catch (e) {
              FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
                  reason: 'Failed to load chat in CustomerChatListScreen');
              Get.back();
              Get.snackbar('Error', 'Failed to load chat: $e',
                  backgroundColor: Colors.redAccent, colorText: Colors.white);
            }
          },
          emptyStateWidget: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline, color: Colors.orange, size: 40),
                SizedBox(height: 8),
                Text("No Chat_System available",
                    style: TextStyle(color: Colors.orange, fontSize: 16)),
                SizedBox(height: 8),
                Text("Start a chat from the Orders page",
                    style: TextStyle(color: Colors.orange, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
