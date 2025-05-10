import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:food_ui/screens/Splash_Screen/splash_screen.dart';
import 'package:food_ui/controller/cart_controller.dart';
import 'package:food_ui/controller/address_controller.dart';
import 'package:food_ui/controller/auth_controller.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'Chat_System/Classes/timestamp_adapter.dart';
import 'Chat_System/Classes/user_cache.dart';
import 'controller/chat_controller.dart';
import 'controller/favoritesController.dart';
import 'controller/order_controller.dart';
import 'controller/product_detail_controller.dart';
import 'controller/product_update _controller.dart';
import 'controller/user_controller.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  await GetStorage.init(); // Initialize GetStorage
  await Hive.initFlutter();
  Hive.registerAdapter(TimestampAdapter());
  await UserCache.init();

  // Initialize Awesome Notifications
  await AwesomeNotifications().initialize(
    'resource://mipmap/ic_launcher', // Use mipmap for launcher icon
    [
      NotificationChannel(
        channelKey: 'order_notifications',
        channelName: 'Order Notifications',
        channelDescription: 'Notifications for order updates',
        defaultColor: Colors.orange,
        ledColor: Colors.white,
        importance: NotificationImportance.High,
      ),
    ],
  );

  // Initialize GetX controllers
  Get.put(AuthController());
  Get.put(UserController());
  Get.put(FavoritesController());
  Get.put(ProductController());
  Get.put(CartController());
  Get.put(OrderController());
  Get.put(AddressController());
  Get.put(ChatController());
  Get.put(ProductDetailController());

  // Load initial theme from Firestore
  bool isDarkMode = false;
  final authController = Get.find<AuthController>();
  if (authController.firebaseUser.value != null) {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(authController.userId)
        .get();
    isDarkMode = userDoc.exists && userDoc.get('darkMode') == true;
  }

  runApp(MyApp(initialThemeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light));
}

class MyApp extends StatelessWidget {
  final ThemeMode initialThemeMode;

  const MyApp({super.key, required this.initialThemeMode});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
        ),
        cardColor: Colors.orange,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.orange,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(Colors.white),
          trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? Colors.orange[700]
              : Colors.orange[300]),
        ),
      ),
      darkTheme: ThemeData(
        primaryColor: Colors.orange,
        scaffoldBackgroundColor: Colors.grey[900],
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
        cardColor: Colors.orange[800],
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.orange,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(Colors.white),
          trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? Colors.orange[700]
              : Colors.orange[300]),
        ),
      ),
      themeMode: initialThemeMode,
      home: SplashScreen(),
    );
  }
}
