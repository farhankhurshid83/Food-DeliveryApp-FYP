import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_ui/screens/add_to_cart_page.dart';
import 'package:get/get.dart';
import '../controller/cart_controller.dart';
import '../screens/chats/customer_chat_list_screen.dart';
import '../screens/favorites_page.dart';
import '../screens/home_screen.dart';
import '../screens/orders_page.dart';
import '../widgets/drawer.dart';

class NavigationController extends GetxController {
  var tabIndex = 0.obs;

  void changeTabIndex(int index) {
    tabIndex.value = index;
    HapticFeedback.lightImpact();
  }
}

class CustomBottomNavBar extends StatelessWidget {
  CustomBottomNavBar({super.key});

  final NavigationController controller = Get.put(NavigationController());
  final CartController cartController = Get.put(CartController());
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // Pass the same scaffoldKey to HomePage
  late final List<Widget> screens = [
    HomePage(scaffoldKey: scaffoldKey),
    FavoriteScreen(),
    CartPage(),
    OrdersPage(),
    const CustomerChatListScreen(),
  ];

  // Define which screens should have a drawer
  Widget? getDrawerForIndex(int index) {
    if (index == 0) {
      return buildDrawer(); // Only HomePage gets the drawer
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => Scaffold(
        key: scaffoldKey,
        drawer: getDrawerForIndex(controller.tabIndex.value),
        body: screens[controller.tabIndex.value],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.orange,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                spreadRadius: 3,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BottomNavigationBar(
              currentIndex: controller.tabIndex.value,
              onTap: controller.changeTabIndex,
              backgroundColor: Colors.transparent,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white.withValues(alpha: 0.7),
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              showUnselectedLabels: false,
              showSelectedLabels: true,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              items: [
                _buildNavItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  index: 0,
                  currentIndex: controller.tabIndex.value,
                ),
                _buildNavItem(
                  icon: Icons.favorite_outline,
                  label: 'Favorites',
                  index: 1,
                  currentIndex: controller.tabIndex.value,
                ),
                _buildNavItem(
                  icon: Icons.shopping_cart_outlined,
                  label: 'Cart',
                  index: 2,
                  currentIndex: controller.tabIndex.value,
                  badgeCount: cartController.cartItems.length,
                ),
                _buildNavItem(
                  icon: Icons.assignment_ind_outlined,
                  label: 'Orders',
                  index: 3,
                  currentIndex: controller.tabIndex.value,
                ),
                _buildNavItem(
                  icon: Icons.headset_mic_outlined,
                  label: 'Support',
                  index: 4,
                  currentIndex: controller.tabIndex.value,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required int currentIndex,
    int? badgeCount,
  }) {
    return BottomNavigationBarItem(
      icon: Stack(
        children: [
          AnimatedScale(
            scale: currentIndex == index ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutBack,
            child: BorderedIcon(
              icon: icon,
              isSelected: currentIndex == index,
            ),
          ),
          if (badgeCount != null && index == 2 && badgeCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      label: label,
    );
  }
}

class BorderedIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;

  const BorderedIcon({super.key, required this.icon, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isSelected
            ? const LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: isSelected ? null : Colors.white.withValues(alpha: 0.15),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 3,
          ),
        ]
            : [],
      ),
      child: Icon(
        icon,
        color: isSelected ? Colors.orange : Colors.white.withValues(alpha: 0.9),
        size: isSelected ? 23 : 28,
      ),
    );
  }
}
