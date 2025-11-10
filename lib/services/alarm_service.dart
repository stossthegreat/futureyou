import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/habit.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const String _channelId = 'habit_reminders';
  static const String _channelName = 'Habit Reminders';
  static const String _channelDescription = 'Notifications for habit reminders';

  /// Call once from main() after WidgetsFlutterBinding.ensureInitialized().
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Initialize AndroidAlarmManager
    try {
      await AndroidAlarmManager.initialize();
      debugPrint('✅ AndroidAlarmManager initialized');
    } catch (e) {
      debugPrint('⚠️ AndroidAlarmManager init failed: $e');
    }

    // Ask runtime permissions where required (Android 13+)
    await _requestPermissions();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: android, iOS: ios);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createNotificationChannel();
    debugPrint('✅ AlarmService initialized');
  }

  static Future<void> _requestPermissions() async {
    try {
      // Notifications
      final nStatus = await Permission.notification.status;
      if (nStatus.isDenied || nStatus.isRestricted) {
        await Permission.notification.request();
      }

      // Exact Alarm (Android 12+ app-op; no-op where unsupported)
      final eStatus = await Permission.scheduleExactAlarm.status;
      if (eStatus.isDenied || eStatus.isRestricted) {
        await Permission.scheduleExactAlarm.request();
      }
    } catch (e) {
      debugPrint('⚠️ Permission request failed: $e');
    }
  }

  static Future<void> _createNotificationChannel() async {
    // CHANGED: Using UriAndroidNotificationSound to play system alarm sound
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
      sound: UriAndroidNotificationSound('content://settings/system/alarm_alert'), // ← SYSTEM ALARM SOUND
      enableVibration: true,
      enableLights: true,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    // TODO: handle deep-link / navigation if desired
  }

  // ---------------- DAILY MAINTENANCE CHECK ----------------
  static Future<void> scheduleDailyCheck() async {
    try {
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
      debugPrint('🕔 Daily check scheduled for $start');
    } catch (e) {
      debugPrint('⚠️ scheduleDailyCheck failed: $e');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _dailyCheckCallback() async {
    debugPrint('🕔 Daily check triggered.');
    // TODO: put streak reset / maintenance here if needed
  }

  // ---------------- HABIT ALARMS ----------------
  /// Schedule weekly notifications for a habit. **Only** if habit.reminderOn == true.
  static Future<void> scheduleAlarm(Habit habit) async {
    if (!habit.reminderOn) {
      debugPrint('⏰ scheduleAlarm skipped: reminder OFF for "${habit.title}"');
      return;
    }
    await cancelAlarm(habit.id);

    // CHANGED: Using system alarm sound instead of default notification sound
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: UriAndroidNotificationSound('content://settings/system/alarm_alert'), // ← SYSTEM ALARM SOUND
      enableVibration: true,
      enableLights: true,
      audioAttributesUsage: AudioAttributesUsage.alarm, // ← TREAT AS ALARM, NOT NOTIFICATION
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    final details = NotificationDetails(android: androidDetails, iOS: iOSDetails);

    for (final day in habit.repeatDays) {
      final time = _nextWeeklyInstance(day, habit.timeOfDay);
      final id = _notifId(habit.id, day);

      await _notifications.zonedSchedule(
        id,
        '🔥 ${habit.title}',
        _getQuote(),
        time,
        details,
        payload: habit.id,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );

      // Manual HH:mm formatting (no BuildContext needed)
      final hh = habit.timeOfDay.hour.toString().padLeft(2, '0');
      final mm = habit.timeOfDay.minute.toString().padLeft(2, '0');
      debugPrint('⏰ Scheduled "${habit.title}" on weekday=$day at $hh:$mm (id=$id, tz=$time)');
    }
  }

  static Future<void> cancelAlarm(String habitId) async {
    for (int d = 0; d < 7; d++) {
      await _notifications.cancel(_notifId(habitId, d));
    }
    debugPrint('🧹 Cancelled alarms for $habitId');
  }

  static Future<void> cancelAll() async => _notifications.cancelAll();

  /// weekday0Sun6Sat maps to tz week (Mon=1..Sun=7). We map 0→7.
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
