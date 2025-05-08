import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/order_controller.dart' as oc;
import '../controller/user_controller.dart';
import '../widgets/custom_btn.dart';
import 'order_detailPage.dart';

class CustomerOrder extends StatelessWidget {
  final oc.OrderController orderController = Get.find<oc.OrderController>();
  final UserController userController = Get.find<UserController>();

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
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to fetch delivery boys');
      return [];
    }
  }

  Future<bool> _confirmAction(BuildContext context, String action) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          '$action Order',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        content: Text(
          'Are you sure you want to $action this order?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'No',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Yes',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> _showDialog(BuildContext context, String title, String message,
      {bool isError = false}) async {
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          title,
          style: TextStyle(
            color: isError ? Colors.orange : Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(message, style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
              expandedHeight: 100,
              pinned: true,
              iconTheme: IconThemeData(
                color: Colors.white,
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Customer Orders',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.orange,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.receipt_long_outlined,
                      size: 36,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.all(12),
                child: Obx(() {
                  // Check if orders are still loading
                  if (orderController.orders.isEmpty &&
                      orderController.orders.value == null) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height - 180,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.orange,
                        ),
                      ),
                    );
                  }
                  // Handle empty orders
                  if (orderController.orders.isEmpty) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height - 180,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fastfood_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No Orders Available',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  // Filter orders with valid createdAt
                  final validOrders = orderController.orders
                      .where((order) => order.createdAt != null)
                      .toList();
                  if (validOrders.isEmpty) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height - 180,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.warning_amber_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No Valid Orders Found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: List.generate(
                      validOrders.length,
                          (index) {
                        final order = validOrders[index];
                        return GestureDetector(
                          onTap: () => Get.to(
                                () => OrderDetailsPage(order: order),
                            transition: Transition.rightToLeft,
                            duration: Duration(milliseconds: 400),
                          ),
                          child: Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: 4, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(2, 2),
                                ),
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(-2, -2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Order #${order.id.substring(order.id.length - 6)}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        'Rs ${order.total.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  FutureBuilder<String>(
                                    future: userController
                                        .getDisplayName(order.customerId),
                                    builder: (context, snapshot) => Text(
                                      'Customer: ${snapshot.data ?? order.customerName}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[800],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Address: ${order.address}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(
                                          order.status,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white),
                                        ),
                                        backgroundColor:
                                        _getStatusColor(order.status),
                                        avatar: Icon(
                                          _getStatusIcon(order.status),
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      SizedBox(width: 8),
                                      Chip(
                                        label: Text(
                                          order.paymentStatus == 'pending'
                                              ? 'Awaiting Payment'
                                              : 'Paid',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white),
                                        ),
                                        backgroundColor:
                                        order.paymentStatus == 'pending'
                                            ? Colors.orange[600]
                                            : Colors.green[600],
                                        avatar: Icon(
                                          order.paymentStatus == 'pending'
                                              ? Icons.hourglass_empty
                                              : Icons.check_circle,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ],
                                  ),
                                  if (order.status != 'Cancelled' &&
                                      order.status != 'Rejected' &&
                                      order.status != 'Delivered')
                                    Padding(
                                      padding: EdgeInsets.only(top: 12),
                                      child: _buildActionButtons(
                                          context, order, orderController),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.blue[600]!;
      case 'accepted':
        return Colors.green[600]!;
      case 'rejected':
        return Colors.red[600]!;
      case 'cancelled':
        return Colors.grey[600]!;
      case 'delivered':
        return Colors.teal[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'cancelled':
        return Icons.block;
      case 'delivered':
        return Icons.local_shipping;
      default:
        return Icons.info;
    }
  }

  Widget _buildActionButtons(
      BuildContext context, oc.Order order, oc.OrderController orderController) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (order.paymentStatus == 'pending')
          CustomButton(
            buttonText: 'Confirm',
            textStyle: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
            icon: Icon(Icons.check, size: 16, color: Colors.white),
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
            buttonColor: Colors.orange,
            borderRadius: 10,
            width: 90,
          ),
        if (order.paymentStatus == 'pending')
          CustomButton(
            buttonText: 'Reject',
            textStyle: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
            icon: Icon(Icons.close, size: 16, color: Colors.white),
            onPressed: () async {
              bool confirm = await _confirmAction(context, 'Reject');
              if (confirm) {
                try {
                  await orderController.rejectOrder(order.id);
                  await _showDialog(
                    context,
                    'Order Rejected',
                    'Order #${order.id.substring(order.id.length - 6)} rejected.',
                  );
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
            buttonColor: Colors.orange[600]!,
            borderRadius: 10,
            width: 90,
          ),
        if (order.paymentStatus == 'paid' && !order.isAccepted)
          FutureBuilder<List<Map<String, String>>>(
            future: _fetchDeliveryBoys(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  width: 90,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(1, 1)),
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(-1, -1)),
                    ],
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.orange,
                    ),
                  ),
                );
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return Container(
                  width: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(1, 1)),
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(-1, -1)),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'No Delivery',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                );
              }
              var deliveryBoys = snapshot.data!;
              var selectedDeliveryBoy = ''.obs;
              return Obx(
                    () => Container(
                  width: 90,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(1, 1)),
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(-1, -1)),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'Assign',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      value: selectedDeliveryBoy.value.isEmpty
                          ? null
                          : selectedDeliveryBoy.value,
                      items: deliveryBoys
                          .map(
                            (boy) => DropdownMenuItem(
                          value: boy['id'],
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              boy['name']!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      )
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
                      icon: Icon(Icons.arrow_drop_down,
                          color: Colors.orange, size: 20),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87),
                      dropdownColor: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        CustomButton(
          buttonText: 'Cancel',
          textStyle: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
          icon: Icon(Icons.block, size: 16, color: Colors.white),
          onPressed: () async {
            bool confirm = await _confirmAction(context, 'Cancel');
            if (confirm) {
              try {
                await orderController.cancelOrder(order.id);
                await _showDialog(
                  context,
                  'Order Cancelled',
                  'Order #${order.id.substring(order.id.length - 6)} cancelled.',
                );
              } catch (e) {
                await _showDialog(
                  context,
                  'Error',
                  'Failed to cancel: $e',
                  isError: true,
                );
              }
            }
          },
          buttonColor: Colors.grey[600]!,
          borderRadius: 10,
          width: 90,
        ),
      ],
    );
  }
}
