// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
// class NotificationService {
//   static final FlutterLocalNotificationsPlugin _notificationsPlugin =
//   FlutterLocalNotificationsPlugin();
//
//   static Future<void> init() async {
//     const AndroidInitializationSettings initializationSettingsAndroid =
//     AndroidInitializationSettings('launcher_icon');
//
//     const InitializationSettings initializationSettings = InitializationSettings(
//       android: initializationSettingsAndroid,
//     );
//
//     await _notificationsPlugin.initialize(initializationSettings);
//
//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'order_notifications',
//       'Order Notifications',
//       description: 'Notifications for order updates',
//       importance: Importance.high,
//     );
//
//     await _notificationsPlugin
//         .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);
//   }
//
//   static Future<void> showNotification({
//     required int id,
//     required String title,
//     required String body,
//   }) async {
//     const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//       'order_notifications',
//       'Order Notifications',
//       channelDescription: 'Notifications for order updates',
//       importance: Importance.high,
//       priority: Priority.high,
//     );
//
//     const NotificationDetails notificationDetails =
//     NotificationDetails(android: androidDetails);
//
//     await _notificationsPlugin.show(id, title, body, notificationDetails);
//   }
// }