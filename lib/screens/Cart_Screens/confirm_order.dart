import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:food_ui/screens/Cart_Screens/payment_Screen.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controller/address_controller.dart';
import '../../controller/auth_controller.dart';
import '../../controller/cart_controller.dart';
import '../../controller/order_controller.dart' as oc;
import '../../widgets/custom_btn.dart';
import '../Drawer/drawerPages/adress_page.dart';

class ConfirmOrderPage extends StatelessWidget {
  final CartController cartController = Get.find<CartController>();
  final oc.OrderController orderController = Get.find<oc.OrderController>();
  final AuthController authController = Get.find<AuthController>();
  final AddressController addressController = Get.find<AddressController>();

  void placeOrder() async {
    if (addressController.selectedAddress.isEmpty) {
      Get.snackbar(
        "Error",
        "Please select a delivery address",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    try {
      String customerName = "Customer";
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(authController.userId)
          .get();
      if (userDoc.exists) {
        customerName = userDoc['displayName'] ?? "Customer";
      }

      String orderId = await orderController.placeOrder(
        customerId: authController.userId,
        customerName: customerName,
        address: addressController.selectedAddress.value,
        cartItems: cartController.cartItems,
        subtotal: cartController.subtotal.value,
        delivery: cartController.delivery.value,
        total: cartController.total.value,
      );

      Get.to(() => PaymentPage(
        orderId: orderId,
        amount: cartController.total.value,
        currency: "pkr",
      ));
    } catch (e) {
      String message = e is FirebaseException ? e.message ?? "Unknown error" : e.toString();
      Get.snackbar(
        "Error",
        "Failed to place order: $message",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Failed to place order');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text(
          "Confirm Your Order",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
      ),
      body: Obx(() => Column(
        children: [
          Expanded(
            child: cartController.cartItems.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Your cart is empty",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cartController.cartItems.length,
              itemBuilder: (context, index) {
                final item = cartController.cartItems[index];
                final String name = item["name"] ?? "Unknown Item";
                final String imageBase64 = item["image"] ?? "";
                final double price = (item["price"] is num
                    ? item["price"]
                    : double.tryParse(item["price"]?.toString() ?? '0.0')) ??
                    0.0;
                final int quantity = item["quantity"] ?? 1;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: SizedBox(
                      width: 50,
                      height: 50,
                      child: imageBase64.isNotEmpty
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(imageBase64),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.image,
                              size: 30,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      )
                          : Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.image,
                          size: 30,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      "Rs ${price.toStringAsFixed(2)} x $quantity",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: Text(
                      "Rs ${(price * quantity).toStringAsFixed(2)}",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange, // Updated color
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Wrap Container in Flexible to limit its height
          Flexible(
            fit: FlexFit.loose,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Order Summary",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryRow(
                        "Subtotal",
                        "Rs ${cartController.subtotal.value.toStringAsFixed(2)}",
                      ),
                      _buildSummaryRow(
                        "Delivery",
                        "Rs ${cartController.delivery.value.toStringAsFixed(2)}",
                      ),
                      const Divider(height: 20, thickness: 1),
                      _buildSummaryRow(
                        "Total",
                        "Rs ${cartController.total.value.toStringAsFixed(2)}",
                        isTotal: true,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.orange, // Updated color
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.5,
                                child: Text(
                                  addressController.selectedAddress.value.isEmpty
                                      ? "No delivery address selected"
                                      : addressController.selectedAddress.value,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () => Get.to(() => AddressListPage()),
                            child: Text(
                              addressController.selectedAddress.value.isEmpty
                                  ? "Add"
                                  : "Change",
                              style: GoogleFonts.poppins(
                                color: Colors.orange, // Updated color
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: CustomButton(
                          buttonText: "Proceed to Payment",
                          textStyle: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          onPressed: placeOrder,
                          buttonColor: Colors.orange, // Updated color
                          borderRadius: 12,
                          icon: const Icon(
                            Icons.payment,
                            color: Colors.white,
                            size: 20,
                          ),
                          width: double.infinity,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.black54,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: isTotal ? Colors.orange : Colors.black87, // Updated color
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
