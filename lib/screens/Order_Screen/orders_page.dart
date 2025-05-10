import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../controller/auth_controller.dart';
import '../../../controller/chat_controller.dart';
import '../../../controller/order_controller.dart' as oc;
import '../../../controller/user_controller.dart';
import '../../Chat_System/chat_view_screen.dart';

class OrdersPage extends StatelessWidget {
  final oc.OrderController orderController = Get.find<oc.OrderController>();
  final AuthController authController = Get.find<AuthController>();
  final UserController userController = Get.find<UserController>();
  final ChatController chatController = Get.find<ChatController>();

  Future<bool> _confirmCancel(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              "Cancel Order",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            content: Text(
              "Are you sure you want to cancel this order?",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  "No",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  "Yes",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _confirmDeleteOrder(BuildContext context,
      {bool isAll = false}) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              isAll ? "Delete All Orders" : "Delete Order",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            content: Text(
              isAll
                  ? "Are you sure you want to delete all your orders? This action cannot be undone."
                  : "Are you sure you want to delete this order? This action cannot be undone.",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  "No",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  "Yes",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text(
          'My Orders',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              orderController.setFilter(value);
            },
            color: Colors.white, // Set dropdown background to white
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'All',
                child: Text(
                  'All',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black, // Set text color to black
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: 'Today',
                child: Text(
                  'Today',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: 'Tomorrow',
                child: Text(
                  'Tomorrow',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: 'Last Week',
                child: Text(
                  'Last Week',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'delete_all') {
                bool confirm = await _confirmDeleteOrder(context, isAll: true);
                if (confirm) {
                  try {
                    await orderController
                        .deleteAllOrders(authController.userId);
                  } catch (e) {
                    FirebaseCrashlytics.instance.recordError(
                      e,
                      StackTrace.current,
                      reason: 'Failed to delete all orders',
                    );
                  }
                }
              }
            },
            color: Colors.white, // Set dropdown background to white
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'delete_all',
                child: Text(
                  'Delete All Orders',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black, // Set text color to black
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        final orders = orderController.getFilteredOrders(authController.userId);
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  "No orders found",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildOrderSection(
              context,
              "Active",
              orders
                  .where((order) =>
                      order.status == "Pending" ||
                      order.status == "Accepted" ||
                      order.status == "In Progress" ||
                      order.status == "On The Way")
                  .toList(),
            ),
            _buildOrderSection(
              context,
              "Completed",
              orders.where((order) => order.status == "Delivered").toList(),
            ),
            _buildOrderSection(
              context,
              "Cancelled/Rejected",
              orders
                  .where((order) =>
                      order.status == "Cancelled" || order.status == "Rejected")
                  .toList(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildOrderSection(
      BuildContext context, String title, List<oc.Order> orders) {
    if (orders.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        ...orders.map((order) => Card(
              elevation: 7,
              color: Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  "Order #${order.id}",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                subtitle: FutureBuilder<String>(
                  future: userController.getDisplayName(order.customerId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text(
                        "Loading...",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Text(
                        "Error loading customer name",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total: Rs ${order.total.toStringAsFixed(2)}",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          "Status: ${order.status}",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          "Payment: ${order.paymentStatus == 'pending' ? 'Awaiting Confirmation' : 'Paid'}",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: order.paymentStatus == 'pending'
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                        Text(
                          "Customer: ${snapshot.data ?? order.customerName}",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (order.status == "Pending" &&
                        order.paymentStatus == 'pending')
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () async {
                          bool confirm = await _confirmCancel(context);
                          if (confirm) {
                            try {
                              await orderController.cancelOrder(order.id);
                            } catch (e) {
                              FirebaseCrashlytics.instance.recordError(
                                e,
                                StackTrace.current,
                                reason: 'Failed to cancel order',
                              );
                            }
                          }
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        bool confirm = await _confirmDeleteOrder(context);
                        if (confirm) {
                          try {
                            await orderController.deleteOrder(order.id);
                          } catch (e) {
                            FirebaseCrashlytics.instance.recordError(
                              e,
                              StackTrace.current,
                              reason: 'Failed to delete order',
                            );
                          }
                        }
                      },
                    ),
                    if (order.status == "Delivered")
                      const Icon(Icons.check_circle, color: Colors.green),
                    if (order.deliveryBoyId != null &&
                        order.status != "Delivered")
                      IconButton(
                        icon: const Icon(Icons.chat, color: Colors.blue),
                        onPressed: () {
                          try {
                            chatController.setOrderChatContext(
                              orderId: order.id,
                              customerId: authController.userId,
                              deliveryBoyId: order.deliveryBoyId!,
                            );
                            Get.to(() => ChatViewScreen());
                          } catch (e) {
                            Get.snackbar(
                              "Error",
                              "Failed to open chat: $e",
                              backgroundColor: Colors.redAccent,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            FirebaseCrashlytics.instance.recordError(
                              e,
                              StackTrace.current,
                              reason: 'Failed to open order chat',
                            );
                          }
                        },
                      ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
