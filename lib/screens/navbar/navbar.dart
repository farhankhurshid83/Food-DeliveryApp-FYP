import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../../Chat_System/customer_chat_list_screen.dart';
import '../../controller/cart_controller.dart';
import '../Drawer/drawer.dart';
import '../Home_Screen/home_screen.dart';
import '../Cart_Screens/cart_screen.dart';
import '../Navbar_Screens/favorites_page.dart';
import '../Order_Screen/orders_page.dart';

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

  late final List<Widget> screens = [
    HomePage(scaffoldKey: scaffoldKey),
    FavoriteScreen(),
    CartPage(),
    OrdersPage(),
    const CustomerChatListScreen(),
  ];

  Widget? getDrawerForIndex(int index) {
    if (index == 0) {
      return buildDrawer();
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
        bottomNavigationBar: CurvedNavigationBar(
          index: controller.tabIndex.value,
          height: 60.0,
          items: [
            _buildNavItem(
              context: context, // Pass context
              icon: Icons.home_outlined,
              label: 'Home',
              index: 0,
              currentIndex: controller.tabIndex.value,
            ),
            _buildNavItem(
              context: context,
              icon: Icons.favorite_outline,
              label: 'Favorites',
              index: 1,
              currentIndex: controller.tabIndex.value,
            ),
            _buildNavItem(
              context: context,
              icon: Icons.shopping_cart_outlined,
              label: 'Cart',
              index: 2,
              currentIndex: controller.tabIndex.value,
              badgeCount: cartController.cartItems.length,
            ),
            _buildNavItem(
              context: context,
              icon: Icons.assignment_ind_outlined,
              label: 'Orders',
              index: 3,
              currentIndex: controller.tabIndex.value,
            ),
            _buildNavItem(
              context: context,
              icon: Icons.headset_mic_outlined,
              label: 'Support',
              index: 4,
              currentIndex: controller.tabIndex.value,
            ),
          ],
          color: Theme.of(context).primaryColor,
          buttonBackgroundColor: Colors.orange,
          backgroundColor: Colors.transparent,
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 300),
          onTap: controller.changeTabIndex,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context, // Add context parameter
    required IconData icon,
    required String label,
    required int index,
    required int currentIndex,
    int? badgeCount,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          icon,
          size: 30,
          color: currentIndex == index
              ? Colors.white
              : Colors.white.withValues(alpha: 0.9),
        ),
        if (badgeCount != null && index == 2 && badgeCount > 0)
          Positioned(
            right: 0,
            top: -3,
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
    );
  }
}
