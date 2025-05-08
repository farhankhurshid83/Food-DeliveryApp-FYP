import 'package:flutter/material.dart';
import 'package:food_ui/screens/chats/admin_chat_list_screen.dart';
import 'package:get/get.dart';
import '../controller/auth_controller.dart';
import '../controller/chat_controller.dart';
import '../widgets/admin_card.dart';
import 'add_newDeliveryBoy.dart';
import 'add_product_screen.dart';
import 'coustmer_order.dart';
import 'delete_product_screen.dart';
import 'update_product_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  void _logout() async {
    try {
      await AuthController.instance.logout();
    } catch (e) {
      debugPrint("Error during logout: $e");
      if (Get.context != null) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          const SnackBar(content: Text("Error during logout")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Get.find<ChatController>();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.orange.shade300,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("Admin Panel", style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white
          ),),
          backgroundColor: Colors.orange,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white,),
              onPressed: _logout,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                AdminCard(
                  title: "Add Product",
                  icon: Icons.add_box,
                  onTap: () => Get.to(() => AddProductPage()),
                ),
                AdminCard(
                  title: "Delete Product",
                  icon: Icons.delete,
                  onTap: () => Get.to(() => DeleteProductScreen()),
                ),
                AdminCard(
                  title: "Update Product",
                  icon: Icons.update,
                  onTap: () => Get.to(() => UpdateProductScreen()),
                ),
                AdminCard(
                  title: "Customer Orders",
                  icon: Icons.pending_actions_outlined,
                  onTap: () => Get.to(() => CustomerOrder()),
                ),
                AdminCard(
                  title: "Add Delivery Boy",
                  icon: Icons.add_outlined,
                  onTap: () => Get.to(() => AddDeliveryBoyScreen()),
                ),
                const Divider(
                  color: Colors.white,
                ),
                AdminCard(
                  title: "Chat Lists",
                  icon: Icons.chat,
                  onTap: () => Get.to(() => AdminChatListScreen()),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}