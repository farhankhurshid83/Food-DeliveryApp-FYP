import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/auth_controller.dart';
import '../screens/adress_page.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/drawerPages/contactUs.dart';
import '../screens/drawerPages/help.dart';
import '../screens/drawerPages/settingPage.dart';

Widget buildDrawer() {
  final AuthController authController = Get.find<AuthController>();

  return Drawer(
    child: Container(
      color: Colors.orange,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Obx(() {
            final user = authController.firebaseUser.value;
            return UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Colors.orange,
                border: Border(
                  bottom: Divider.createBorderSide(
                    Get.context!,
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              accountName:Text(
                user?.displayName ??
                    (user?.email != null
                        ? '${user!.email!.split('@').first[0].toUpperCase()}${user.email!.split('@').first.substring(1)}'
                        : 'Guest User'),
                style: GoogleFonts.yujiBoku(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            accountEmail: Text(
                user?.email ?? "No Email",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: user?.email != null
                    ? null
                    : null, // We won't use backgroundImage when showing initials/icon
                child: user?.email != null
                    ? Text(
                  user!.email![0].toUpperCase(), // First letter uppercase
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : const Icon(
                  Icons.person,
                  color: Colors.orange,
                  size: 28,
                ),
              ),

              margin: EdgeInsets.zero,
            );
          }),
          _buildDrawerItem(
            Icons.location_on_outlined,
            "Delivery Address",
                () => Get.to(AddressListPage()),
          ),
          _buildDrawerItem(
            Icons.support_agent,
            "About Us",
                () => Get.to(const AboutUsPage()),
          ),
          _buildDrawerItem(
            Icons.help_outline,
            "Help & FAQs",
                () => Get.to(const HelpPage()),
          ),
          _buildDrawerItem(
            Icons.settings,
            "Settings",
                () => Get.to(const SettingsPage()),
          ),
          Divider(
            color: Colors.black.withValues(alpha: 0.3),
            thickness: 1,
            indent: 16,
            endIndent: 16,
          ),
          _buildDrawerItem(
            Icons.logout,
            "Log Out",
                () async {
              await authController.logout();
              Get.offAllNamed('/login');
            },
          ),
        ],
      ),
    ),
  );
}

Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        hoverColor: Colors.white.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
