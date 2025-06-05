
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotiService {
  final notificationPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initNotification() async {
    if (_isInitialized) return;

    const initSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    await notificationPlugin.initialize(initSettings);
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel_id',
        'Daily Notifications',
        channelDescription: 'Daily Notification Channel',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  // Order Notification
  NotificationDetails orderDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'order_channel',
        'Order Notifications',
        channelDescription: 'Notifications about orders',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  // Promotional Notification
  NotificationDetails promoDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'promo_channel',
        'Promotions',
        channelDescription: 'Promotional offers and discounts',
        importance: Importance.high,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  // Reminder Notification
  NotificationDetails reminderDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'reminder_channel',
        'Reminders',
        channelDescription: 'Daily or scheduled reminders',
        importance: Importance.defaultImportance,
        priority: Priority.low,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    return notificationPlugin.show(id, title, body, notificationDetails());
  }

  // Show Order Notification
  Future<void> showOrderNotification({
    int id = 1,
    String? title,
    String? body,
  }) async {
    return notificationPlugin.show(id, title, body, orderDetails());
  }

  // Show Promotional Notification
  Future<void> showPromoNotification({
    int id = 2,
    String? title,
    String? body,
  }) async {
    return notificationPlugin.show(id, title, body, promoDetails());
  }

  // Show Reminder Notification
  Future<void> showReminderNotification({
    int id = 3,
    String? title,
    String? body,
  }) async {
    return notificationPlugin.show(id, title, body, reminderDetails());
  }
}