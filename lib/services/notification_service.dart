import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings: settings);
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleMorningReminder(String time) async {
    await cancelNotification(1);
    await _plugin.periodicallyShow(
      id: 1,
      title: 'RoutineFuel',
      body: 'Take your morning breakfast',
      repeatInterval: RepeatInterval.daily,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'morning_reminder',
          'Morning Reminder',
          channelDescription: 'Daily morning routine reminder',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> showLowStockAlert(List<String> items) async {
    if (items.isEmpty) return;
    final body = items.length == 1
        ? '${items.first} stock is running low'
        : '${items.length} items are running low: ${items.take(3).join(', ')}';
    await _plugin.show(
      id: 2,
      title: 'Low Stock Alert',
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'low_stock',
          'Low Stock Alerts',
          channelDescription: 'Alerts when inventory is low',
          importance: Importance.defaultImportance,
          category: AndroidNotificationCategory.status,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showShoppingReminder(int itemCount) async {
    await _plugin.show(
      id: 3,
      title: 'Shopping Reminder',
      body: 'You have $itemCount items on your shopping list',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'shopping_reminder',
          'Shopping Reminders',
          channelDescription: 'Reminders to go shopping',
          importance: Importance.defaultImportance,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
