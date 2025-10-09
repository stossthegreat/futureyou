import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/habit.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'habit_reminders';
  static const String _channelName = 'Habit Reminders';
  static const String _channelDescription = 'Notifications for habit reminders';

  static Future<void> initialize() async {
    await _requestPermissions();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: android, iOS: ios);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createNotificationChannel();
  }

  static Future<void> _requestPermissions() async {
    await Permission.notification.request();
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  static Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
  }

  // --------------- DAILY MAINTENANCE CHECK ---------------
  static Future<void> scheduleDailyCheck() async {
    final now = DateTime.now();
    var start = DateTime(now.year, now.month, now.day, 5, 0);
    if (start.isBefore(now)) start = start.add(const Duration(days: 1));
    await AndroidAlarmManager.oneShotAt(
      start,
      9000001,
      _dailyCheckCallback,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _dailyCheckCallback() async {
    debugPrint('🕔 Daily check triggered.');
  }

  // --------------- HABIT ALARMS ----------------

  static Future<void> scheduleAlarm(Habit habit) async {
    if (!habit.reminderOn) return;
    await cancelAlarm(habit.id);

    for (final day in habit.repeatDays) {
      final time = _nextWeeklyInstance(day, habit.timeOfDay);
      final id = _notifId(habit.id, day);

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      );

      await _notifications.zonedSchedule(
        id,
        '🔥 ${habit.title}',
        _getQuote(),
        time,
        details,
        payload: habit.id,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  static Future<void> cancelAlarm(String habitId) async {
    for (int d = 0; d < 7; d++) {
      await _notifications.cancel(_notifId(habitId, d));
    }
  }

  static Future<void> cancelAll() async => _notifications.cancelAll();

  static tz.TZDateTime _nextWeeklyInstance(int weekday0Sun6Sat, TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    final target = (weekday0Sun6Sat == 0) ? 7 : weekday0Sun6Sat;
    while (scheduled.weekday != target || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static int _notifId(String habitId, int day) =>
      ((habitId.hashCode.abs() % 900000) + 100000) * 10 + day;

  static String _getQuote() {
    const q = [
      "Your future self is counting on you.",
      "Discipline beats motivation.",
      "Consistency builds destiny.",
      "Every action shapes tomorrow.",
      "Small wins, huge future.",
      "Future You is watching — act now."
    ];
    final i = DateTime.now().minute % q.length;
    return q[i];
  }
}
