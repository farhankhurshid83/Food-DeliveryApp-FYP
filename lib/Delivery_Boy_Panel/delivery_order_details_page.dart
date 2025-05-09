import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryOrderDetailsPage extends StatefulWidget {
  final String orderId;
  final String status;
  final String customerId;
  final String customerName;
  final String address;
  final double total;
  final List<dynamic> items;

  const DeliveryOrderDetailsPage({
    Key? key,
    required this.orderId,
    required this.status,
    required this.customerId,
    required this.customerName,
    required this.address,
    required this.total,
    required this.items,
  }) : super(key: key);

  @override
  _DeliveryOrderDetailsPageState createState() => _DeliveryOrderDetailsPageState();
}

class _DeliveryOrderDetailsPageState extends State<DeliveryOrderDetailsPage> {
  String dropdownValue = '';

  @override
  void initState() {
    super.initState();
    // Initialize dropdown with current status or fallback
    const validStatuses = ['Pending', 'Accepted', 'Picked Up', 'Delivered'];
    dropdownValue = validStatuses.contains(widget.status) ? widget.status : 'Pending';
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    try {
      // Update order status
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
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
          notificationBody = 'Your order #${widget.orderId.substring(widget.orderId.length - 6)} is pending.';
          break;
        case 'Accepted':
          notificationBody = 'Your order #${widget.orderId.substring(widget.orderId.length - 6)} has been accepted.';
          break;
        case 'Picked Up':
          notificationBody = 'Your order #${widget.orderId.substring(widget.orderId.length - 6)} has been picked up.';
          break;
        case 'Delivered':
          notificationBody = 'Your order #${widget.orderId.substring(widget.orderId.length - 6)} has been delivered.';
          break;
        default:
          notificationBody = 'Your order #${widget.orderId.substring(widget.orderId.length - 6)} status is $newStatus.';
      }

      await FirebaseFirestore.instance.collection('notifications').add({
        'customerId': widget.customerId,
        'orderId': widget.orderId,
        'title': notificationTitle,
        'body': notificationBody,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Update dropdown value
      setState(() {
        dropdownValue = newStatus;
      });
    } catch (e) {
      Get.snackbar("Error", "Failed to update status: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.orange.shade200,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              color: Colors.orange,
            ),
          ),
          title: Text(
            "Order #${widget.orderId.substring(widget.orderId.length - 6)}",
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionCard(
                title: "Customer Details",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 22, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Name: ${widget.customerName}",
                            style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 22, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Address: ${widget.address}",
                            style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildSectionCard(
                title: "Order Items",
                child: Column(
                  children: widget.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              "${item['name']} x${item['quantity']}",
                              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            "₹${(item['price'] * item['quantity']).toStringAsFixed(2)}",
                            style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              _buildSectionCard(
                title: "Order Summary",
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total",
                          style: TextStyle(fontSize: 16, color: Colors.grey[800], fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "₹${widget.total.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Status",
                          style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: dropdownValue,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: dropdownValue == 'Delivered' ? Colors.grey : Colors.orange,
                            ),
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                              DropdownMenuItem(value: 'Accepted', child: Text('Accepted')),
                              DropdownMenuItem(value: 'Picked Up', child: Text('Picked Up')),
                              DropdownMenuItem(value: 'Delivered', child: Text('Delivered')),
                            ],
                            onChanged: dropdownValue == 'Delivered'
                                ? (String? newValue) {
                              Get.snackbar(
                                "Info",
                                "Cannot change status after delivery",
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.orange,
                                colorText: Colors.white,
                              );
                            }
                                : (String? newValue) {
                              if (newValue != null && newValue != widget.status) {
                                _updateOrderStatus(newValue);
                              }
                            },
                            style: TextStyle(
                              color: dropdownValue == 'Delivered' ? Colors.grey : Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            dropdownColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

}