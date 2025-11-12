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
          'time': habit.time, // CRITICAL: Pass time so callback can reschedule
        },
      );

      // Manual HH:mm formatting (no BuildContext needed)
      final hh = habit.timeOfDay.hour.toString().padLeft(2, '0');
      final mm = habit.timeOfDay.minute.toString().padLeft(2, '0');
      debugPrint('⏰ REAL ALARM Scheduled "${habit.title}" on weekday=$day at $hh:$mm (id=$id)');
    }
  }

  /// This callback fires when the alarm time is reached
  /// CRITICAL: This runs in a SEPARATE ISOLATE - must initialize everything!
  @pragma('vm:entry-point')
  static Future<void> _alarmCallback(int id, Map<String, dynamic>? params) async {
    debugPrint('🔥🔥🔥 ALARM FIRING! ID: $id, Params: $params');
    
    try {
      // CRITICAL: Initialize Flutter bindings for this isolate
      WidgetsFlutterBinding.ensureInitialized();
      debugPrint('✅ Flutter bindings initialized in alarm callback');

      // Get habit info from params
      final habitTitle = params?['habitTitle'] ?? 'Habit Reminder';
      final habitId = params?['habitId'] ?? '';
      final day = params?['day'] ?? 0;
      final timeStr = params?['time'] ?? '';

      debugPrint('📋 Alarm details: title="$habitTitle", habitId=$habitId, day=$day, time=$timeStr');

      // Initialize notification plugin in THIS isolate
      final notifications = FlutterLocalNotificationsPlugin();
      
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
      
      await notifications.initialize(initSettings);
      debugPrint('✅ Notification plugin initialized in callback');

      // Create notification channel in THIS isolate (Android requirement)
      const androidChannel = AndroidNotificationChannel(
        'habit_reminders',
        'Habit Reminders',
        description: 'Notifications for habit reminders',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      );
      
      await notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
      debugPrint('✅ Notification channel created in callback');

      // Show notification with system sound
      const androidDetails = AndroidNotificationDetails(
        'habit_reminders',
        'Habit Reminders',
        channelDescription: 'Notifications for habit reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true, // Uses system default notification sound
        enableVibration: true,
        enableLights: true,
        ongoing: false, // Allow dismissal
        autoCancel: true, // Dismiss when tapped
        fullScreenIntent: true, // Show as full screen on lock screen
        styleInformation: BigTextStyleInformation(
          _getQuote(),
          contentTitle: '🔥 $habitTitle',
          summaryText: 'Tap to complete',
        ),
      );

      const iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await notifications.show(
        id,
        '🔥 $habitTitle',
        _getQuote(),
        const NotificationDetails(android: androidDetails, iOS: iOSDetails),
        payload: habitId,
      );
      debugPrint('✅ Notification shown successfully');

      // Reschedule for next week (same day, same time)
      // IMPORTANT: We need to extract the time properly
      final timeParts = timeStr.split(':');
      if (timeParts.length == 2) {
        final hour = int.tryParse(timeParts[0]) ?? 9;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        final nextTime = _nextWeeklyInstanceForCallback(day, TimeOfDay(hour: hour, minute: minute));
        
        await AndroidAlarmManager.oneShotAt(
          nextTime.toLocal(),
          id,
          _alarmCallback,
          exact: true,
          wakeup: true,
          allowWhileIdle: true,
          rescheduleOnReboot: true,
          params: params,
        );
        debugPrint('🔁 Rescheduled alarm for: $nextTime (next occurrence on weekday $day)');
      } else {
        debugPrint('⚠️ Could not parse time "$timeStr" for rescheduling');
      }

    } catch (e, stackTrace) {
      debugPrint('❌ Alarm callback error: $e');
      debugPrint('📚 Stack trace: $stackTrace');
    }
  }

  /// Helper for callback isolate (needs timezone init)
  static tz.TZDateTime _nextWeeklyInstanceForCallback(int weekday0Sun6Sat, TimeOfDay time) {
    try {
      // Initialize timezone data in callback isolate
      tz.initializeTimeZones();
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
    } catch (e) {
      debugPrint('⚠️ Timezone init failed in callback, using UTC: $e');
      // Fallback to simple DateTime
      final now = DateTime.now();
      return tz.TZDateTime.from(now.add(const Duration(days: 7)), tz.local);
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

  // ============================================================
  // DEBUGGING & VERIFICATION METHODS
  // ============================================================

  /// Schedule a test alarm that fires in 1 minute
  static Future<void> scheduleTestAlarm() async {
    try {
      final now = DateTime.now();
      final testTime = now.add(const Duration(minutes: 1));
      const testId = 999999; // Unique ID for test alarm
      
      await AndroidAlarmManager.oneShotAt(
        testTime,
        testId,
        _testAlarmCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        params: {
          'habitTitle': 'TEST ALARM',
          'habitId': 'test',
          'day': 0,
          'time': '${testTime.hour}:${testTime.minute}',
        },
      );
      
      debugPrint('🧪 TEST ALARM scheduled for: $testTime (in 1 minute)');
      debugPrint('🧪 Current time: $now');
    } catch (e) {
      debugPrint('❌ Test alarm scheduling failed: $e');
    }
  }

  /// Test alarm callback (same as main callback but with test markers)
  @pragma('vm:entry-point')
  static Future<void> _testAlarmCallback(int id, Map<String, dynamic>? params) async {
    debugPrint('🧪🧪🧪 TEST ALARM FIRING! This proves the alarm system works!');
    // Call the main alarm callback
    await _alarmCallback(id, params);
  }

  /// Get list of all currently scheduled alarms
  static List<Map<String, dynamic>> getScheduledAlarms() {
    return _scheduledAlarms.entries.map((entry) {
      return {
        'id': entry.key,
        'habitTitle': entry.value['habitTitle'] ?? 'Unknown',
        'habitId': entry.value['habitId'] ?? 'Unknown',
        'day': entry.value['day'] ?? 0,
      };
    }).toList();
  }

  /// Verify if a specific habit has alarms scheduled
  static Map<String, dynamic> verifyAlarmScheduled(String habitId) {
    final alarms = <Map<String, dynamic>>[];
    
    for (int d = 0; d < 7; d++) {
      final id = _notifId(habitId, d);
      if (_scheduledAlarms.containsKey(id)) {
        alarms.add({
          'day': d,
          'alarmId': id,
          'data': _scheduledAlarms[id],
        });
      }
    }
    
    return {
      'habitId': habitId,
      'alarmsScheduled': alarms.length,
      'alarms': alarms,
    };
  }

  /// Get count of all scheduled alarms
  static int getScheduledAlarmCount() {
    return _scheduledAlarms.length;
  }
}
