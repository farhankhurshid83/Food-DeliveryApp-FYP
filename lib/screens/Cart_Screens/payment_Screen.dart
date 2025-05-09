import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/cart_controller.dart';
import '../../controller/order_controller.dart' as oc;
import '../../widgets/custom_btn.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentPage extends StatefulWidget {
  final String orderId;
  final double amount;
  final String currency;

  const PaymentPage({
    Key? key,
    required this.orderId,
    required this.amount,
    required this.currency,
  }) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final CartController cartController = Get.find<CartController>();
  final oc.OrderController orderController = Get.find<oc.OrderController>();
  bool isLoading = false;
  String? errorMessage;
  String selectedPaymentMethod = 'qr';

  final String easyPaisaAccount = "03XX-XXXXXXX";
  final String jazzCashAccount = "03XX-XXXXXXX";

  Future<String?> _fetchQrUrl() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('config').doc('payment').get();
      return doc.data()?['easyPaisaQrUrl'];
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to load QR code",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  void handleQrPayment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          "Pay with EasyPaisa QR",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Scan the QR code below to pay with EasyPaisa:"),
              SizedBox(height: 16),
              FutureBuilder<String?>(
                future: _fetchQrUrl(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(  color: Colors.orange,));
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Image.asset(
                      'assets/images/easypaisa_qr.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    );
                  }
                  return Image.network(
                    snapshot.data!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/images/easypaisa_qr.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              Text("Amount: Rs ${widget.amount.toStringAsFixed(2)}"),
              Text("Order ID: ${widget.orderId}"),
              SizedBox(height: 8),
              Text("Steps:"),
              Text("1. Open your EasyPaisa app."),
              Text("2. Go to 'Scan QR' or 'Pay via QR'."),
              Text("3. Scan the QR code above."),
              Text("4. Enter the amount shown and Order ID in the reference."),
              Text("5. Confirm payment and return here."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final url = Uri.parse("easypaisa://");
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                Get.snackbar(
                  "Error",
                  "EasyPaisa app not installed",
                  backgroundColor: Colors.redAccent,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: Text(
              "Open EasyPaisa",
              style: TextStyle(   color: Colors.orange,),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              cartController.clearCart();
              Get.back();
              Get.snackbar(
                "Info",
                "Payment sent. We'll confirm soon!",
                backgroundColor: Colors.blue,
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: Text(
              "Done",
              style: TextStyle(   color: Colors.orange,),
            ),
          ),
        ],
      ),
    );
  }

  void handleEasyPaisaPayment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          "Pay with EasyPaisa",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Please transfer the amount to the following EasyPaisa account:"),
              SizedBox(height: 8),
              Text(
                "Account: $easyPaisaAccount",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text("Amount: Rs ${widget.amount.toStringAsFixed(2)}"),
              Text("Order ID: ${widget.orderId}"),
              SizedBox(height: 8),
              Text("Steps:"),
              Text("1. Open your EasyPaisa app."),
              Text("2. Go to 'Send Money'."),
              Text("3. Enter the account number and amount."),
              Text("4. Include the Order ID in the reference."),
              Text("5. Confirm payment and return here."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final url = Uri.parse("easypaisa://");
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                Get.snackbar(
                  "Error",
                  "EasyPaisa app not installed",
                  backgroundColor: Colors.redAccent,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: Text(
              "Open EasyPaisa",
              style: TextStyle(   color: Colors.orange,),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              cartController.clearCart();
              Get.back();
              Get.snackbar(
                "Info",
                "Payment sent. We'll confirm soon!",
                backgroundColor: Colors.blue,
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: Text(
              "Done",
              style: TextStyle(   color: Colors.orange,),
            ),
          ),
        ],
      ),
    );
  }

  void handleJazzCashPayment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          "Pay with JazzCash",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Please transfer the amount to the following JazzCash account:"),
              SizedBox(height: 8),
              Text(
                "Account: $jazzCashAccount",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text("Amount: Rs ${widget.amount.toStringAsFixed(2)}"),
              Text("Order ID: ${widget.orderId}"),
              SizedBox(height: 8),
              Text("Steps:"),
              Text("1. Open your JazzCash app."),
              Text("2. Go to 'Send Money'."),
              Text("3. Enter the account number and amount."),
              Text("4. Include the Order ID in the reference."),
              Text("5. Confirm payment and return here."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final url = Uri.parse("jazzcash://");
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                Get.snackbar(
                  "Error",
                  "JazzCash app not installed",
                  backgroundColor: Colors.redAccent,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: Text(
              "Open JazzCash",
              style: TextStyle(   color: Colors.orange,),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              cartController.clearCart();
              Get.back();
              Get.snackbar(
                "Info",
                "Payment sent. We'll confirm soon!",
                backgroundColor: Colors.blue,
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: Text(
              "Done",
              style: TextStyle(   color: Colors.orange,),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:Colors.orange,
        title: Text(
          "Payment",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Pay for Order #${widget.orderId}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Amount: Rs ${widget.amount.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Currency: ${widget.currency.toUpperCase()}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              "Select Payment Method",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Column(
              children: [
                RadioListTile<String>(
                  title: Text("EasyPaisa QR"),
                  value: 'qr',
                  groupValue: selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      selectedPaymentMethod = value!;
                    });
                  },
                  activeColor: Colors.orange,
                ),
                RadioListTile<String>(
                  title: Text("EasyPaisa Manual"),
                  value: 'easypaisa',
                  groupValue: selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      selectedPaymentMethod = value!;
                    });
                  },
                  activeColor: Colors.orange,
                ),
                RadioListTile<String>(
                  title: Text("JazzCash"),
                  value: 'jazzcash',
                  groupValue: selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      selectedPaymentMethod = value!;
                    });
                  },
                  activeColor:  Colors.orange,
                ),
              ],
            ),
            SizedBox(height: 24),
            if (errorMessage != null)
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  errorMessage!,
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                  ),
                ),
              ),
            Center(
              child: CustomButton(
                buttonText: isLoading ? "Processing..." : "Pay Now",
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                onPressed: isLoading
                    ? () {}
                    : () {
                  if (selectedPaymentMethod == 'qr') {
                    handleQrPayment();
                  } else if (selectedPaymentMethod == 'easypaisa') {
                    handleEasyPaisaPayment();
                  } else if (selectedPaymentMethod == 'jazzcash') {
                    handleJazzCashPayment();
                  }
                },
                buttonColor:  Colors.orange,
                borderRadius: 12,
                icon: Icon(
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
    );
  }
}
