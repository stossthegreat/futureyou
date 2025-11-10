import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:audioplayers/audioplayers.dart';

import '../models/habit.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _initialized = false;

  static const String _channelId = 'habit_reminders';
  static const String _channelName = 'Habit Reminders';
  static const String _channelDescription = 'Notifications for habit reminders';

  // Store scheduled alarms in memory to track them
  static final Map<int, Map<String, dynamic>> _scheduledAlarms = {};

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
    
    // Set audio player to maximum volume and alarm mode
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
    await _audioPlayer.setVolume(1.0);
    
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
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    // Stop the alarm sound when notification is tapped
    _audioPlayer.stop();
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
  /// Schedule weekly alarms for a habit. **Only** if habit.reminderOn == true.
  static Future<void> scheduleAlarm(Habit habit) async {
    if (!habit.reminderOn) {
      debugPrint('⏰ scheduleAlarm skipped: reminder OFF for "${habit.title}"');
      return;
    }
    await cancelAlarm(habit.id);

    for (final day in habit.repeatDays) {
      final nextTime = _nextWeeklyInstance(day, habit.timeOfDay);
      final id = _notifId(habit.id, day);

      // Store alarm info for the callback
      _scheduledAlarms[id] = {
        'habitTitle': habit.title,
        'habitId': habit.id,
        'day': day,
      };

      // Schedule using AndroidAlarmManager for reliable wake-up
      await AndroidAlarmManager.oneShotAt(
        nextTime.toLocal(),
        id,
        _alarmCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
        params: {
          'habitTitle': habit.title,
          'habitId': habit.id,
          'day': day,
        },
      );

      // Manual HH:mm formatting (no BuildContext needed)
      final hh = habit.timeOfDay.hour.toString().padLeft(2, '0');
      final mm = habit.timeOfDay.minute.toString().padLeft(2, '0');
      debugPrint('⏰ REAL ALARM Scheduled "${habit.title}" on weekday=$day at $hh:$mm (id=$id)');
    }
  }

  /// This callback fires when the alarm time is reached
  @pragma('vm:entry-point')
  static Future<void> _alarmCallback(int id, Map<String, dynamic>? params) async {
    debugPrint('🔥🔥🔥 ALARM FIRING! ID: $id');
    
    try {
      // Get habit info
      final habitTitle = params?['habitTitle'] ?? 'Habit Reminder';
      final habitId = params?['habitId'] ?? '';
      final day = params?['day'] ?? 0;

      // Play alarm sound using system alarm tone
      // This uses the phone's default alarm sound
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop); // Loop the sound
      await player.setVolume(1.0); // Max volume
      
      // Try to play system alarm sound (this works on most Android devices)
      try {
        await player.play(AssetSource('audio/alarm.mp3')); // We'll add a fallback
      } catch (e) {
        debugPrint('⚠️ Custom alarm sound failed, trying system notification: $e');
        // Fallback: just vibrate and show notification
      }

      // Show notification with action buttons
      const androidDetails = AndroidNotificationDetails(
        'habit_reminders',
        'Habit Reminders',
        channelDescription: 'Notifications for habit reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ongoing: true, // Can't be dismissed by swiping
        autoCancel: false,
        fullScreenIntent: true, // Show as full screen on lock screen
      );

      const iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await FlutterLocalNotificationsPlugin().show(
        id,
        '🔥 $habitTitle',
        _getQuote(),
        const NotificationDetails(android: androidDetails, iOS: iOSDetails),
        payload: habitId,
      );

      // Stop sound after 30 seconds
      Future.delayed(const Duration(seconds: 30), () {
        player.stop();
        debugPrint('⏰ Alarm sound stopped after 30 seconds');
      });

      // Reschedule for next week (same day, same time)
      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));
      await AndroidAlarmManager.oneShotAt(
        nextWeek,
        id,
        _alarmCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
        params: params,
      );
      debugPrint('🔁 Rescheduled alarm for next week: $nextWeek');

    } catch (e) {
      debugPrint('❌ Alarm callback error: $e');
    }
  }

  static Future<void> cancelAlarm(String habitId) async {
    for (int d = 0; d < 7; d++) {
      final id = _notifId(habitId, d);
      await AndroidAlarmManager.cancel(id);
      await _notifications.cancel(id);
      _scheduledAlarms.remove(id);
    }
    debugPrint('🧹 Cancelled alarms for $habitId');
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
    for (final id in _scheduledAlarms.keys) {
      await AndroidAlarmManager.cancel(id);
    }
    _scheduledAlarms.clear();
  }

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
