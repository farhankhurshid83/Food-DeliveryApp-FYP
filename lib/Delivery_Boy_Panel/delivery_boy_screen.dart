import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../Chat_System/delivery_boy_chat_list_screen.dart';
import '../controller/auth_controller.dart';
import '../widgets/custom_btn.dart';
import 'delivery_order_details_page.dart';

class DeliveryBoyScreen extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();

  void _logout() async {
    try {
      await AuthController.instance.logout();
    } catch (e) {
      debugPrint("Error during logout: $e");
      Get.snackbar("Error", "Failed to logout: $e",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Colors.orange,
          ),
        ),
        title: const Text("Delivery Dashboard", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              Get.snackbar("Refreshing", "Reloading orders...",
                  duration: const Duration(seconds: 1),
                  backgroundColor: Colors.blueGrey,
                  colorText: Colors.white);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildOrderList()),
          Center(
            child: CustomButton(
              buttonText: "View Chats",
              textStyle: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
              onPressed: () {
                Get.to(() => DeliveryBoyChatListScreen());
              },
              borderRadius: 30,
              buttonColor: Colors.orange,
              width: MediaQuery.of(context).size.width * 0.5,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                backgroundImage: authController.firebaseUser.value?.photoURL != null
                    ? CachedNetworkImageProvider(authController.firebaseUser.value!.photoURL!)
                    : null,
                child: authController.firebaseUser.value?.photoURL == null
                    ? const Icon(Icons.person, size: 30, color: Colors.orange)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Welcome, ${authController.firebaseUser.value?.displayName ?? 'Delivery Partner'}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('deliveryBoyId', isEqualTo: authController.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.orange)));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                const SizedBox(height: 8),
                Text("Error loading orders", style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox, color: Colors.grey[500], size: 40),
                const SizedBox(height: 8),
                Text("No assigned orders", style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var order = snapshot.data!.docs[index];
            String orderId = order.id;
            String status = order['status'] ?? 'Pending';
            String customerId = order['customerId'] ?? 'Unknown';
            String customerName = order['customerName'] ?? 'Unknown';
            String address = order['address'] ?? 'No address';
            double total = (order['total'] ?? 0.0).toDouble();
            List<dynamic> items = order['items'] ?? [];

            return _buildOrderCard(
              orderId,
              status,
              customerId,
              customerName,
              address,
              total,
              items,
              context,
            );
          },
        );
      },
    );
  }

  Widget _buildOrderCard(
      String orderId,
      String status,
      String customerId,
      String customerName,
      String address,
      double total,
      List<dynamic> items,
      BuildContext context,
      ) {
    return GestureDetector(
      onTap: () {
        Get.to(() => DeliveryOrderDetailsPage(
          orderId: orderId,
          status: status,
          customerId: customerId,
          customerName: customerName,
          address: address,
          total: total,
          items: items,
        ));
      },
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.orange.withValues(alpha: 0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        "Order #${orderId.substring(orderId.length - 6)}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusTag(status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 22, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Customer: $customerName",
                        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 22, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Address: $address",
                        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.monetization_on_outlined, size: 22, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      "Total: ₹${total.toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (status == 'Pending' || status == 'Accepted')
                      CustomButton(
                        buttonText: "Mark as Picked Up",
                        textStyle: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                        onPressed: () async {
                          await _updateOrderStatus(orderId, 'Picked Up', customerId);
                        },
                        borderRadius: 20,
                        buttonColor: Colors.orange,
                        width: 140,
                      ),
                    const SizedBox(width: 8),
                    if (status == 'Picked Up')
                      CustomButton(
                        buttonText: "Mark as Delivered",
                        textStyle: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                        onPressed: () async {
                          await _updateOrderStatus(orderId, 'Delivered', customerId);
                        },
                        borderRadius: 20,
                        buttonColor: Colors.green,
                        width: 140,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTag(String status) {
    Color tagColor;
    IconData tagIcon;
    switch (status) {
      case 'Pending':
        tagColor = Colors.orange;
        tagIcon = Icons.pending;
        break;
      case 'Accepted':
        tagColor = Colors.yellow[700]!;
        tagIcon = Icons.check;
        break;
      case 'Picked Up':
        tagColor = Colors.blue;
        tagIcon = Icons.local_shipping;
        break;
      case 'Delivered':
        tagColor = Colors.green;
        tagIcon = Icons.check_circle;
        break;
      default:
        tagColor = Colors.grey;
        tagIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tagColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tagIcon, size: 16, color: tagColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tagColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus, String customerId) async {
    try {
      // Update order status
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify delivery boy
      Get.snackbar("Success", "Order status updated to $newStatus",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);

      // Store notification for customer
      String notificationTitle = 'Order Update';
      String notificationBody;
      switch (newStatus) {
        case 'Pending':
          notificationBody = 'Your order #${orderId.substring(orderId.length - 6)} is pending.';
          break;
        case 'Accepted':
          notificationBody = 'Your order #${orderId.substring(orderId.length - 6)} has been accepted.';
          break;
        case 'Picked Up':
          notificationBody = 'Your order #${orderId.substring(orderId.length - 6)} has been picked up.';
          break;
        case 'Delivered':
          notificationBody = 'Your order #${orderId.substring(orderId.length - 6)} has been delivered.';
          break;
        default:
          notificationBody = 'Your order #${orderId.substring(orderId.length - 6)} status is $newStatus.';
      }

      await FirebaseFirestore.instance.collection('notifications').add({
        'customerId': customerId,
        'orderId': orderId,
        'title': notificationTitle,
        'body': notificationBody,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      Get.snackbar("Error", "Failed to update status: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white);
    }
  }
}
