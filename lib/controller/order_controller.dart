import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final String address;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double delivery;
  final double total;
  final String status;
  final String? deliveryBoyId;
  final String paymentStatus;
  final bool isAccepted;
  final Timestamp? createdAt;

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.address,
    required this.items,
    required this.subtotal,
    required this.delivery,
    required this.total,
    required this.status,
    this.deliveryBoyId,
    required this.paymentStatus,
    required this.isAccepted,
    this.createdAt,
  });

  factory Order.fromMap(String id, Map<String, dynamic> data) {
    return Order(
      id: id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      address: data['address'] ?? '',
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      delivery: (data['delivery'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'Pending',
      deliveryBoyId: data['deliveryBoyId'],
      paymentStatus: data['paymentStatus'] ?? 'pending',
      isAccepted: data['isAccepted'] ?? false,
      createdAt: data['createdAt'],
    );
  }
}

class OrderController extends GetxController {
  var orders = <Order>[].obs;
  var filter = 'All'.obs; // Filter state: All, Today, Tomorrow, Last Week


  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  void fetchOrders() {
    FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        orders.value = snapshot.docs
            .map((doc) => Order.fromMap(doc.id, doc.data()))
            .toList();
      },
      onError: (e) {
        Get.snackbar('Error', 'Failed to fetch orders: $e');
      },
    );
  }

  List<Order> getFilteredOrders(String userId) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(Duration(days: 1));
    final lastWeekStart = todayStart.subtract(Duration(days: 7));

    return orders.where((order) {
      if (order.customerId != userId) return false;
      if (filter.value == 'All') return true;
      if (order.createdAt == null) return false;

      final orderDate = order.createdAt!.toDate();
      switch (filter.value) {
        case 'Today':
          return orderDate.isAfter(todayStart) &&
              orderDate.isBefore(tomorrowStart);
        case 'Tomorrow':
          return orderDate.isAfter(tomorrowStart) &&
              orderDate.isBefore(tomorrowStart.add(Duration(days: 1)));
        case 'Last Week':
          return orderDate.isAfter(lastWeekStart) &&
              orderDate.isBefore(todayStart);
        default:
          return true;
      }
    }).toList();
  }

  void setFilter(String newFilter) {
    filter.value = newFilter;
  }

  Future<String> placeOrder({
    required String customerId,
    required String customerName,
    required String address,
    required List<Map<String, dynamic>> cartItems,
    required double subtotal,
    required double delivery,
    required double total,
  }) async {
    try {
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();
      await orderRef.set({
        'customerId': customerId,
        'customerName': customerName,
        'address': address,
        'items': cartItems,
        'subtotal': subtotal,
        'delivery': delivery,
        'total': total,
        'status': 'Pending',
        'paymentStatus': 'pending',
        'isAccepted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
// await NotificationService.showNotification(
//   id: _notificationIdCounter++,
//   title: 'New Order #${orderRef.id.substring(orderRef.id.length - 6)}',
//   body: 'A new order of Rs ${total.toStringAsFixed(2)} is pending.',
// );
// await NotificationService.showNotification(
//   id: _notificationIdCounter++,
//   title: 'Order Placed',
//   body: 'Your order #${orderRef.id.substring(orderRef.id.length - 6)} is pending payment.',
// );
      return orderRef.id;
    } catch (e) {
      Get.snackbar('Error', 'Failed to place order: $e');
      rethrow;
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': 'Cancelled'});
// await NotificationService.showNotification(
//   id: _notificationIdCounter++,
//   title: 'Order Cancelled',
//   body: 'Order #${orderId.substring(orderId.length - 6)} has been cancelled.',
// );
    } catch (e) {
      Get.snackbar('Error', 'Failed to cancel order: $e');
      rethrow;
    }
  }

  Future<void> rejectOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': 'Rejected'});
// await NotificationService.showNotification(
//   id: _notificationIdCounter++,
//   title: 'Order Rejected',
//   body: 'Order #${orderId.substring(orderId.length - 6)} has been rejected.',
// );
    } catch (e) {
      Get.snackbar('Error', 'Failed to reject order: $e');
      rethrow;
    }
  }

  Future<void> acceptOrder(String orderId, String deliveryBoyId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'deliveryBoyId': deliveryBoyId,
        'isAccepted': true,
        'status': 'Accepted',
      });
// await NotificationService.showNotification(
//   id: _notificationIdCounter++,
//   title: 'New Assignment',
//   body: 'You are assigned to order #${orderId.substring(orderId.length - 6)}.',
// );
// await NotificationService.showNotification(
//   id: _notificationIdCounter++,
//   title: 'Order Accepted',
//   body: 'Your order #${orderId.substring(orderId.length - 6)} has been accepted.',
// );
    } catch (e) {
      Get.snackbar('Error', 'Failed to accept order: $e');
      rethrow;
    }
  }

  Future<void> confirmPayment(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'paymentStatus': 'paid'});
// await NotificationService.showNotification(
//   id: _notificationIdCounter++,
//   title: 'Payment Confirmed',
//   body: 'Payment for order #${orderId.substring(orderId.length - 6)} has been confirmed.',
// );
// await NotificationService.showNotification(
//   id: _notificationIdCounter++,
//   title: 'Payment Received',
//   body: 'Payment for order #${orderId.substring(orderId.length - 6)} is confirmed.',
// );
    } catch (e) {
      Get.snackbar('Error', 'Failed to confirm payment: $e');
      rethrow;
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .delete();
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete order: $e');
      rethrow;
    }
  }

  Future<void> deleteAllOrders(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('customerId', isEqualTo: userId)
          .get();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete all orders: $e');
      rethrow;
    }
  }
}
