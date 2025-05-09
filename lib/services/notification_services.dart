import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AwesomeNotificationService {
  static int _notificationIdCounter = 0;

  static Future<void> init() async {
    // Request permission for notifications
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? channelKey = 'order_notifications',
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _notificationIdCounter++,
          channelKey: channelKey ?? 'order_notifications',
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          color: Colors.orange,
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to show notification: $e');
    }
  }
}
