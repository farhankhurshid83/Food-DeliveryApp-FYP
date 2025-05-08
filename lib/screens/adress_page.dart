import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/address_controller.dart';
import '../widgets/custom_btn.dart';
import 'new_delivery adress.dart';

class AddressListPage extends StatelessWidget {
  final AddressController addressCtrl = Get.find<AddressController>();

  // Show dialog to confirm deletion
  void _showDeleteDialog(BuildContext context, String address, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Delete Address',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$title"?',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              addressCtrl.deleteAddress(address);
              Get.back();
              Get.snackbar(
                'Success',
                'Address deleted successfully',
                backgroundColor: Colors.green,
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(
                fontSize: 14,
                color: Colors.redAccent,
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
          'Your Addresses',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Obx(() => addressCtrl.addresses.isEmpty
            ? _buildEmptyState(context)
            : _buildAddressList(context)),
      ),
      floatingActionButton: addressCtrl.addresses.isNotEmpty
          ? FloatingActionButton(
        onPressed: () => Get.to(() => AddNewAddressPage()),
        backgroundColor: Colors.orange,
        tooltip: 'Add New Address',
        child: Icon(Icons.add_location, color: Colors.white),
      )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 100,
            color: Colors.orange,
          ),
          SizedBox(height: 16),
          Text(
            "No Addresses Saved",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Add an address to get started!",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          CustomButton(
            buttonText: "Add Address",
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            onPressed: () => Get.to(() => AddNewAddressPage()),
            buttonColor: Colors.orange,
            borderRadius: 12,
            icon: Icon(
              Icons.add_location,
              color: Colors.white,
              size: 20,
            ),
            width: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: addressCtrl.addresses.length,
      itemBuilder: (context, index) {
        final address = addressCtrl.addresses[index];
        final String title = address["title"] ?? "Address";
        final String addr = address["address"] ?? "";

        return Card(
          elevation: 4,
          margin: EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Color(0xffffccbc), // Light orange tint
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: Colors.orange.withValues(alpha: 0.2),
                child: Icon(
                  Icons.location_on,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              title: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              subtitle: Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  addr,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: addressCtrl.selectedAddress.value == addr
                        ? Colors.orange
                        : Colors.grey[300],
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => _showDeleteDialog(context, addr, title),
                    tooltip: 'Delete Address',
                  ),
                ],
              ),
              onTap: () {
                addressCtrl.selectAddress(addr);
                Get.back();
                Get.snackbar(
                  "Success",
                  "Address selected: $title",
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
