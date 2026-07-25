import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    // Android 13+ runtime notification permission.
    final AndroidFlutterLocalNotificationsPlugin? androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
  }

  /// Schedule the daily reminder at [hour]:[minute] (replaces id 1002).
  Future<void> scheduleDailyVerseReminderAt({required int hour, required int minute}) async {
    await _plugin.cancel(1002);
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_verse',
      'Daily Verse',
      channelDescription: 'Daily verse and reading reminders.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    final DateTime now = DateTime.now();
    DateTime next = DateTime(now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      1002,
      'Sakshi Vani',
      'आज का वचन और पठन के लिए खोलें',
      tz.TZDateTime.from(next, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyVerseReminder() async {
    await _plugin.cancel(1002);
  }

  Future<void> scheduleChurchCourtesyReminder() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'church_courtesy',
      'Church Courtesy',
      channelDescription: 'Reminders to keep phone silent during service.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);
    final DateTime now = DateTime.now();
    DateTime next = DateTime(now.year, now.month, now.day, 9, 15);
    while (next.weekday != DateTime.sunday || next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
      next = DateTime(next.year, next.month, next.day, 9, 15);
    }

    await _plugin.zonedSchedule(
      1001,
      'Service Courtesy Reminder',
      'Worship time is near. Consider enabling silent mode.',
      tz.TZDateTime.from(next, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> scheduleDailyVerseReminder() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_verse',
      'Daily Verse',
      channelDescription: 'Daily verse reading reminders.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);
    final DateTime now = DateTime.now();
    DateTime next = DateTime(now.year, now.month, now.day, 6, 30);
    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      1002,
      'Sakshi Vani',
      'आज का वचन पढ़ने के लिए खोलें',
      tz.TZDateTime.from(next, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
