import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/order_controller.dart' as oc;
import '../controller/user_controller.dart';
import '../widgets/custom_btn.dart';

class OrderDetailsPage extends StatelessWidget {
  final oc.Order order;
  final oc.OrderController orderController = Get.find<oc.OrderController>();
  final UserController userController = Get.find<UserController>();

  OrderDetailsPage({Key? key, required this.order}) : super(key: key);

  Future<List<Map<String, String>>> _fetchDeliveryBoys() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'delivery')
          .get();
      final deliveryBoys = snapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc['displayName']?.toString() ?? 'Unknown',
      }).toList();
      return deliveryBoys;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Failed to fetch delivery boys');
      return [];
    }
  }

  Future<bool> _confirmAction(BuildContext context, String action) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('$action Order'),
        content: Text('Are you sure you want to $action this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Yes',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> _showDialog(BuildContext context, String title, String message, {bool isError = false}) async {
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          title,
          style: TextStyle(color: isError ? Colors.orange : Colors.green),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(2, 2)),
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(-2, -2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
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
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              iconTheme: IconThemeData(
                color: Colors.white,
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Order #${order.id.substring(order.id.length - 6)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.receipt_long,
                      size: 60,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionCard(
                      title: 'Customer Details',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<String>(
                            future: userController.getDisplayName(order.customerId),
                            builder: (context, snapshot) => Text(
                              'Name: ${snapshot.data ?? order.customerName}',
                              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                            ),
                          ),
                          Text(
                            'Address: ${order.address}',
                            style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _buildSectionCard(
                      title: 'Order Items',
                      child: Column(
                        children: order.items
                            .map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  '${item['name']} x${item['quantity']}',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'Rs ${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                              ),
                            ],
                          ),
                        ))
                            .toList(),
                      ),
                    ),
                    _buildSectionCard(
                      title: 'Order Summary',
                      child: Column(
                        children: [
                          _buildSummaryRow('Subtotal', 'Rs ${order.subtotal.toStringAsFixed(2)}'),
                          _buildSummaryRow('Delivery', 'Rs ${order.delivery.toStringAsFixed(2)}'),
                          const Divider(height: 20, thickness: 1),
                          _buildSummaryRow(
                            'Total',
                            'Rs ${order.total.toStringAsFixed(2)}',
                            isBold: true,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                    _buildSectionCard(
                      title: 'Order Status',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status: ${order.status}',
                            style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                          ),
                          Text(
                            'Payment: ${order.paymentStatus == 'pending' ? 'Awaiting Confirmation' : 'Paid'}',
                            style: TextStyle(
                              fontSize: 16,
                              color: order.paymentStatus == 'pending' ? Colors.orange : Colors.green,
                            ),
                          ),
                          if (order.createdAt != null)
                            Text(
                              'Placed: ${order.createdAt!.toDate().toString().split('.')[0]}',
                              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                            ),
                          if (order.deliveryBoyId != null)
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(order.deliveryBoyId)
                                  .get(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const SizedBox.shrink();
                                }
                                if (!snapshot.hasData || !snapshot.data!.exists) {
                                  return Text(
                                    'Delivery Boy: Unknown',
                                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                                  );
                                }
                                return Text(
                                  'Delivery Boy: ${snapshot.data!['displayName'] ?? 'Unknown'}',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    if (order.status != 'Cancelled' && order.status != 'Rejected' && order.status != 'Delivered')
                      _buildActionButtons(context, order),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: Colors.grey[800]),
          ),
          Text(
            value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color ?? Colors.grey[800]),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, oc.Order order) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        if (order.paymentStatus == 'pending')
          CustomButton(
            buttonText: 'Confirm Payment',
            textStyle: const TextStyle(fontSize: 14, color: Colors.white),
            onPressed: () async {
              try {
                await orderController.confirmPayment(order.id);
                await _showDialog(
                  context,
                  'Payment Confirmed',
                  'Payment for order #${order.id.substring(order.id.length - 6)} marked as paid.',
                );
              } catch (e) {
                await _showDialog(
                  context,
                  'Error',
                  'Failed to confirm payment: $e',
                  isError: true,
                );
              }
            },
            buttonColor: const Color(0xfff05424),
            borderRadius: 8,
            width: 140,
          ),
        if (order.paymentStatus == 'pending')
          CustomButton(
            buttonText: 'Reject Order',
            textStyle: const TextStyle(fontSize: 14, color: Colors.white),
            onPressed: () async {
              final confirm = await _confirmAction(context, 'Reject');
              if (confirm) {
                try {
                  await orderController.rejectOrder(order.id);
                  await _showDialog(
                    context,
                    'Order Rejected',
                    'Order #${order.id.substring(order.id.length - 6)} has been rejected.',
                  );
                  Get.back();
                } catch (e) {
                  await _showDialog(
                    context,
                    'Error',
                    'Failed to reject order: $e',
                    isError: true,
                  );
                }
              }
            },
            buttonColor: Colors.red,
            borderRadius: 8,
            width: 140,
          ),
        if (order.paymentStatus == 'paid' && !order.isAccepted)
          FutureBuilder<List<Map<String, String>>>(
            future: _fetchDeliveryBoys(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  width: 140,
                  height: 40,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xfff05424),
                    ),
                  ),
                );
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return SizedBox(
                  width: 140,
                  height: 40,
                  child: Center(
                    child: Text(
                      'No Delivery Boys',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                );
              }
              final deliveryBoys = snapshot.data!;
              final selectedDeliveryBoy = ''.obs;
              return Obx(() => Container(
                width: 140,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Assign Delivery',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                    value: selectedDeliveryBoy.value.isEmpty ? null : selectedDeliveryBoy.value,
                    items: deliveryBoys
                        .map((boy) => DropdownMenuItem(
                      value: boy['id'],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          boy['name']!,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ))
                        .toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        selectedDeliveryBoy.value = value;
                        try {
                          await orderController.acceptOrder(order.id, value);
                          await _showDialog(
                            context,
                            'Order Assigned',
                            'Assigned to ${deliveryBoys.firstWhere((b) => b['id'] == value)['name']}',
                          );
                        } catch (e) {
                          await _showDialog(
                            context,
                            'Error',
                            'Failed to assign: $e',
                            isError: true,
                          );
                        }
                      }
                    },
                  ),
                ),
              ));
            },
          ),
        if (!order.isAccepted)
          CustomButton(
            buttonText: 'Cancel Order',
            textStyle: const TextStyle(fontSize: 14, color: Colors.white),
            onPressed: () async {
              final confirm = await _confirmAction(context, 'Cancel');
              if (confirm) {
                try {
                  await orderController.cancelOrder(order.id);
                  await _showDialog(
                    context,
                    'Order Cancelled',
                    'Order #${order.id.substring(order.id.length - 6)} has been cancelled.',
                  );
                  Get.back();
                } catch (e) {
                  await _showDialog(context, 'Error', 'Failed to cancel: $e', isError: true);
                }
              }
            },
            buttonColor: Colors.grey[600]!,
            borderRadius: 8,
            width: 140,
          ),
      ],
    );
  }
}
