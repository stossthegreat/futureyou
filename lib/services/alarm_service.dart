import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/habit.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const String _channelId = 'habit_alarms';
  static const String _channelName = 'Habit Alarms';
  static const String _channelDescription = 'Alarm notifications for habit reminders';

  /// Initialize alarm service - MUST be called from main()
  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('⚠️ AlarmService already initialized');
      return;
    }

    try {
      debugPrint('🔧 Initializing AlarmService...');

      // Step 1: Initialize AndroidAlarmManager
      await AndroidAlarmManager.initialize();
      debugPrint('✅ AndroidAlarmManager initialized');

      // Step 2: Request permissions
      final notifStatus = await Permission.notification.request();
      debugPrint('📱 Notification permission: $notifStatus');

      final alarmStatus = await Permission.scheduleExactAlarm.request();
      debugPrint('⏰ Exact alarm permission: $alarmStatus');

      // Step 3: Initialize notification plugin
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      debugPrint('✅ Notification plugin initialized');

      // Step 4: Create notification channel with MAXIMUM PRIORITY and SOUND
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
        enableVibration: true,
        enableLights: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      debugPrint('✅ Notification channel created with SOUND');

      _initialized = true;
      debugPrint('🎉 AlarmService fully initialized!');
    } catch (e, stack) {
      debugPrint('❌ AlarmService initialization failed: $e');
      debugPrint('Stack trace: $stack');
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
  }

  /// Schedule alarm for a habit
  static Future<void> scheduleAlarm(Habit habit) async {
    if (!habit.reminderOn) {
      debugPrint('⏰ scheduleAlarm skipped: reminderOn=false for "${habit.title}"');
      return;
    }

    if (habit.time.isEmpty) {
      debugPrint('❌ scheduleAlarm FAILED: time is EMPTY for "${habit.title}"');
      return;
    }

    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔔 scheduleAlarm called for "${habit.title}"');
      debugPrint('   - time: ${habit.time}');
      debugPrint('   - reminderOn: ${habit.reminderOn}');
      debugPrint('   - repeatDays: ${habit.repeatDays}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Cancel any existing alarms first
      await cancelAlarm(habit.id);

      int successCount = 0;
      int failCount = 0;

      // Schedule for each repeat day
      for (final day in habit.repeatDays) {
        final alarmId = _getAlarmId(habit.id, day);
        final nextTime = _getNextAlarmTime(day, habit.timeOfDay);

        debugPrint('📅 Scheduling alarm for ${_getDayName(day)}:');
        debugPrint('   - alarmId: $alarmId');
        debugPrint('   - time: ${habit.time}');
        debugPrint('   - next occurrence: $nextTime');

        try {
          final success = await AndroidAlarmManager.oneShotAt(
            nextTime,
            alarmId,
            _alarmCallback,
            exact: true,
            wakeup: true,
            allowWhileIdle: true,
            rescheduleOnReboot: true,
            params: {
              'habitTitle': habit.title,
              'habitId': habit.id,
              'day': day,
              'hour': habit.timeOfDay.hour,
              'minute': habit.timeOfDay.minute,
            },
          );

          if (success) {
            successCount++;
            debugPrint('   ✅ SUCCESS for ${_getDayName(day)}');
          } else {
            failCount++;
            debugPrint('   ❌ FAILED for ${_getDayName(day)}');
          }
        } catch (e) {
          failCount++;
          debugPrint('   ❌ ERROR for ${_getDayName(day)}: $e');
        }
      }

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📊 Alarm scheduling summary for "${habit.title}":');
      debugPrint('   ✅ Success: $successCount');
      debugPrint('   ❌ Failed: $failCount');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e, stack) {
      debugPrint('❌ scheduleAlarm error: $e');
      debugPrint('Stack: $stack');
    }
  }

  /// Alarm callback - THIS FIRES WHEN THE ALARM GOES OFF
  @pragma('vm:entry-point')
  static Future<void> _alarmCallback(int id, Map<String, dynamic>? params) async {
    debugPrint('🔥🔥🔥 ALARM FIRING! 🔥🔥🔥');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('⏰ Alarm ID: $id');
    debugPrint('📦 Params: $params');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      // CRITICAL: Initialize Flutter bindings in this isolate
      WidgetsFlutterBinding.ensureInitialized();

      final habitTitle = params?['habitTitle'] ?? 'Habit Reminder';
      final habitId = params?['habitId'] ?? '';
      final day = params?['day'] ?? 0;
      final hour = params?['hour'] ?? 9;
      final minute = params?['minute'] ?? 0;

      debugPrint('🔔 Alarm details:');
      debugPrint('   - habitTitle: $habitTitle');
      debugPrint('   - habitId: $habitId');
      debugPrint('   - day: $day (${_getDayName(day)})');
      debugPrint('   - time: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');

      // Initialize notification plugin in this isolate
      final notifications = FlutterLocalNotificationsPlugin();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await notifications.initialize(
        const InitializationSettings(android: androidInit),
      );
      debugPrint('✅ Notification plugin initialized in callback');

      // Create notification channel in this isolate
      const channel = AndroidNotificationChannel(
        'habit_alarms',
        'Habit Alarms',
        description: 'Alarm notifications',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
        enableVibration: true,
        enableLights: true,
      );

      await notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      debugPrint('✅ Notification channel created in callback');

      // Show notification with SOUND
      await notifications.show(
        id,
        '🔥 $habitTitle',
        '${_getMotivationalQuote()}\n\nTap to mark as complete',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_alarms',
            'Habit Alarms',
            channelDescription: 'Alarm notifications',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: const RawResourceAndroidNotificationSound('notification'),
            enableVibration: true,
            enableLights: true,
            fullScreenIntent: true,
            ongoing: false,
            autoCancel: true,
            styleInformation: BigTextStyleInformation(
              '${_getMotivationalQuote()}\n\nTap to mark as complete',
              contentTitle: '🔥 $habitTitle',
              summaryText: 'Future You OS',
            ),
          ),
        ),
        payload: habitId,
      );

      debugPrint('✅ Notification shown successfully with SOUND');

      // Reschedule for next week
      final nextTime = _getNextAlarmTimeForCallback(day, hour, minute);
      await AndroidAlarmManager.oneShotAt(
        nextTime,
        id,
        _alarmCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
        params: params,
      );

      debugPrint('🔁 Rescheduled for next occurrence: $nextTime');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e, stack) {
      debugPrint('❌ Alarm callback error: $e');
      debugPrint('Stack: $stack');
    }
  }

  /// Cancel all alarms for a habit
  static Future<void> cancelAlarm(String habitId) async {
    debugPrint('🗑️ Cancelling alarms for habit: $habitId');
    for (int day = 0; day < 7; day++) {
      final id = _getAlarmId(habitId, day);
      await AndroidAlarmManager.cancel(id);
      await _notifications.cancel(id);
    }
    debugPrint('✅ All alarms cancelled for: $habitId');
  }

  /// Cancel all alarms
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
    debugPrint('🗑️ All alarms cancelled');
  }

  /// Get next alarm time for a given day and time
  static DateTime _getNextAlarmTime(int weekday, TimeOfDay time) {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, time.hour, time.minute);

    // Convert weekday: our model uses 0=Sun, 6=Sat
    // Dart uses 1=Mon, 7=Sun
    final targetWeekday = weekday == 0 ? 7 : weekday;

    // Find next occurrence of this weekday
    while (next.weekday != targetWeekday || next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }

    return next;
  }

  /// Get next alarm time in callback (simpler, no dependencies)
  static DateTime _getNextAlarmTimeForCallback(int weekday, int hour, int minute) {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    final targetWeekday = weekday == 0 ? 7 : weekday;

    while (next.weekday != targetWeekday || next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }

    return next;
  }

  /// Generate unique alarm ID
  static int _getAlarmId(String habitId, int day) {
    return ((habitId.hashCode.abs() % 900000) + 100000) * 10 + day;
  }

  /// Get day name for logging
  static String _getDayName(int day) {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[day];
  }

  /// Get motivational quote
  static String _getMotivationalQuote() {
    const quotes = [
      "Your future self is counting on you.",
      "Discipline beats motivation.",
      "Consistency builds destiny.",
      "Every action shapes tomorrow.",
      "Small wins, huge future.",
      "Future You is watching — act now.",
      "Make yourself proud today.",
      "One habit closer to your dreams.",
    ];
    final index = DateTime.now().minute % quotes.length;
    return quotes[index];
  }

  /// Schedule a test alarm (fires in 1 minute)
  static Future<void> scheduleTestAlarm() async {
    try {
      final testTime = DateTime.now().add(const Duration(minutes: 1));
      const testId = 999999;

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🧪 SCHEDULING TEST ALARM');
      debugPrint('   - Current time: ${DateTime.now()}');
      debugPrint('   - Test alarm time: $testTime');
      debugPrint('   - Alarm ID: $testId');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final success = await AndroidAlarmManager.oneShotAt(
        testTime,
        testId,
        _alarmCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        params: {
          'habitTitle': '🧪 TEST ALARM',
          'habitId': 'test',
          'day': 0,
          'hour': testTime.hour,
          'minute': testTime.minute,
        },
      );

      if (success) {
        debugPrint('✅ Test alarm scheduled successfully!');
        debugPrint('⏰ Should fire at: $testTime');
      } else {
        debugPrint('❌ Test alarm scheduling FAILED');
      }
    } catch (e, stack) {
      debugPrint('❌ Test alarm error: $e');
      debugPrint('Stack: $stack');
    }
  }

  /// Check if service is initialized
  static bool isInitialized() {
    return _initialized;
  }
}
