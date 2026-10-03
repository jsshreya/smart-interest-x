import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(settings: settings);

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleDueReminder({
    required int id,
    required String title,
    required String body,
    required DateTime dueDate,
    int daysBefore = 1,
  }) async {
    final reminderDate = dueDate.subtract(Duration(days: daysBefore));

    if (reminderDate.isBefore(DateTime.now())) {
      return;
    }

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(reminderDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'due_reminders',
          'Due Date Reminders',
          channelDescription: 'Reminders for upcoming loan due dates',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'transaction:$id',
    );
  }

  static Future<void> showOverdueNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'overdue_reminders',
          'Overdue Reminders',
          channelDescription: 'Notifications for overdue transactions',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> cancel(int id) async {
    await _notifications.cancel(id: id);
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
