
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/address_controller.dart';
import '../../../controller/auth_controller.dart';
import '../../../widgets/custom_btn.dart';

class AddNewAddressPage extends StatelessWidget {
final TextEditingController nameController = TextEditingController();
final TextEditingController addressController = TextEditingController();
final AddressController addressCtrl = Get.find<AddressController>();
final AuthController authCtrl = Get.find<AuthController>();

AddNewAddressPage() {
// Set nameController based on firebaseUser, same as buildDrawer
final user = authCtrl.firebaseUser.value;
if (user != null) {
nameController.text = user.displayName ??
(user.email != null
? '${user.email!.split('@').first[0].toUpperCase()}${user.email!.split('@').first.substring(1)}'
    : 'Guest User');
} else {
nameController.text = 'Guest User';
}
}

void saveAddress() {
if (nameController.text.isNotEmpty && addressController.text.isNotEmpty) {
final newAddress = {
"title": nameController.text.trim(),
"address": addressController.text.trim(),
};
addressCtrl.addNewAddress(newAddress);
addressCtrl.selectAddress(newAddress["address"]!);
Get.back();
Get.snackbar(
"Success",
"Address saved successfully",
backgroundColor: Colors.green,
colorText: Colors.white,
snackPosition: SnackPosition.BOTTOM,
);
} else {
Get.snackbar(
"Error",
"Please enter both name and address",
backgroundColor: Colors.redAccent,
colorText: Colors.white,
snackPosition: SnackPosition.BOTTOM,
);
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: Colors.grey[100],
appBar: AppBar(
backgroundColor: Colors.orange,
elevation: 0,
leading: IconButton(
icon: Icon(Icons.arrow_back, color: Colors.white),
onPressed: () => Get.back(),
),
title: Text(
'Add New Address',
style: TextStyle(
color: Colors.white,
fontSize: 20,
fontWeight: FontWeight.bold,
),
),
centerTitle: true,
),
body: SafeArea(
child: SingleChildScrollView(
child: Padding(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
"Delivery Information",
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.bold,
color: Colors.black87,
),
),
SizedBox(height: 16),
// Name Input
Card(
elevation: 4,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
child: TextField(
controller: nameController,
decoration: InputDecoration(
labelText: "Name",
hintText: "e.g., Home, Office",
filled: true,
fillColor: Colors.orange.shade50,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: BorderSide.none,
),
prefixIcon: Icon(
Icons.person,
color: Colors.orange,
),
contentPadding: EdgeInsets.symmetric(
vertical: 16,
horizontal: 12,
),
),
keyboardType: TextInputType.name,
),
),
SizedBox(height: 16),
// Address Input
Card(
elevation: 4,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
child: TextField(
controller: addressController,
decoration: InputDecoration(
labelText: "Address",
hintText: "e.g., 123 Main St, City",
filled: true,
fillColor: Colors.orange.shade50,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: BorderSide.none,
),
prefixIcon: Icon(
Icons.location_on,
color: Colors.orange,
),
contentPadding: EdgeInsets.symmetric(
vertical: 16,
horizontal: 12,
),
),
keyboardType: TextInputType.streetAddress,
maxLines: 3,
),
),
SizedBox(height: 24),
// Save Button
Center(
child: CustomButton(
buttonText: "Save Address",
textStyle: TextStyle(
fontSize: 16,
fontWeight: FontWeight.w600,
color: Colors.white,
),
onPressed: saveAddress,
buttonColor: Colors.orange,
borderRadius: 12,
icon: Icon(
Icons.save,
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
);
}
}
