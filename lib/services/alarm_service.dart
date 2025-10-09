import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/habit.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static const String _channelId = 'habit_reminders';
  static const String _channelName = 'Habit Reminders';
  static const String _channelDescription = 'Notifications for habit reminders';
  
  static Future<void> initialize() async {
    // Request permissions
    await _requestPermissions();
    
    // Initialize notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Create notification channel
    await _createNotificationChannel();
  }

  // Schedules a daily 5am check to reset missed streaks
  static Future<void> scheduleDailyCheck() async {
    final now = DateTime.now();
    DateTime start = DateTime(now.year, now.month, now.day, 5, 0);
    if (start.isBefore(now)) start = start.add(const Duration(days: 1));
    await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      9000001, // unique ID for daily check
      _dailyCheckCallback,
      startAt: start,
      rescheduleOnReboot: true,
      allowWhileIdle: true,
      exact: false,
      wakeup: true,
    );
  }
  
  static Future<void> _requestPermissions() async {
    // Request notification permission
    await Permission.notification.request();
    
    // Request exact alarm permission (Android 12+)
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
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );
    
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }
  
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    debugPrint('Notification tapped: ${response.payload}');
    // TODO: Navigate to specific habit or show completion dialog
  }

  @pragma('vm:entry-point')
  static Future<void> _dailyCheckCallback() async {
    // Lightweight isolate-safe callback: re-init timezone if needed and run streak check
    try {
      // Avoid heavy work here; delegate to StreakService via a top-level init
      // NOTE: In a full app, we'd re-init any needed singletons here
      // For now, invoke a streak reset routine through isolate-safe logic is out-of-scope
    } catch (_) {}
  }
  
  static Future<void> scheduleAlarm(Habit habit) async {
    if (!habit.reminderOn) return;
    
    // Cancel existing alarms for this habit
    await cancelAlarm(habit.id);
    
    // Schedule weekly repeating alarms for each repeat day (AndroidAlarmManager.periodic)
    for (int dayOfWeek in habit.repeatDays) {
      final startAt = _nextWeeklyInstance(dayOfWeek, habit.timeOfDay);
      final uniqueId = habit.id.hashCode + dayOfWeek;
      await AndroidAlarmManager.periodic(
        const Duration(days: 7),
        uniqueId,
        _alarmPeriodicCallback,
        startAt: startAt,
        rescheduleOnReboot: true,
        allowWhileIdle: true,
        exact: false,
        wakeup: true,
        params: {
          'habitId': habit.id,
          'habitTitle': habit.title,
          'habitType': habit.type,
        },
      );
    }
  }
  
  static Future<void> _scheduleAlarmForDay(Habit habit, int dayOfWeek) async {
    final now = DateTime.now();
    final timeOfDay = habit.timeOfDay;
    
    // Find the next occurrence of this day of week
    DateTime scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    
    // Adjust to the correct day of week
    while (scheduledDate.weekday % 7 != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    // If the time has already passed today, schedule for next week
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }
    
    // Check if date is within habit's date range
    if (scheduledDate.isAfter(habit.endDate)) {
      return; // Don't schedule beyond end date
    }
    
    final alarmId = _generateAlarmId(habit.id, dayOfWeek);
    
    // Schedule the alarm
    await AndroidAlarmManager.oneShotAt(
      scheduledDate,
      alarmId,
      _alarmCallback,
      exact: true,
      wakeup: true,
      params: {
        'habitId': habit.id,
        'habitTitle': habit.title,
        'habitType': habit.type,
      },
    );
    
    // Also schedule a local notification as backup
    await _scheduleNotification(habit, scheduledDate, alarmId);
  }
  
  static Future<void> _scheduleNotification(
    Habit habit,
    DateTime scheduledDate,
    int notificationId,
  ) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        _getMotivationalQuote(),
        contentTitle: '🔥 ${habit.title}',
        summaryText: 'Future You OS',
      ),
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.zonedSchedule(
      notificationId,
      '🔥 ${habit.title}',
      _getMotivationalQuote(),
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      payload: habit.id,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _alarmPeriodicCallback(int id, Map<String, dynamic> params) async {
    // Show a local notification when periodic alarm fires
    final habitTitle = params['habitTitle'] as String? ?? 'Habit Reminder';
    final habitId = params['habitId'] as String? ?? '$id';
    await _notifications.show(
      habitId.hashCode,
      'Future You OS Reminder',
      '⏰ $habitTitle',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_channel',
          'Habit Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  static tz.TZDateTime _nextWeeklyInstance(int weekday0To6, TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    // Convert tz weekday (Mon=1..Sun=7) to 0..6 alignment
    int target = weekday0To6 == 0 ? 7 : weekday0To6; // Sun as 7
    while (scheduled.weekday != target || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
  
  static String _getMotivationalQuote() {
    final quotes = [
      "Your future self is counting on you right now.",
      "Small actions today, massive results tomorrow.",
      "Discipline is choosing between what you want now and what you want most.",
      "The best time to plant a tree was 20 years ago. The second best time is now.",
      "You are one habit away from a completely different life.",
      "Success is the sum of small efforts repeated day in and day out.",
      "Don't break the chain. Your streak depends on this moment.",
      "Future You is watching. Make them proud.",
      "Consistency beats perfection every single time.",
      "This is your moment to choose growth over comfort.",
    ];
    
    final now = DateTime.now();
    final index = (now.day + now.hour + now.minute) % quotes.length;
    return quotes[index];
  }
  
  @pragma('vm:entry-point')
  static void _alarmCallback(int id, Map<String, dynamic> params) {
    // This callback runs when the alarm fires
    debugPrint('Alarm fired for habit: ${params['habitTitle']}');
    
    // Show immediate notification
    _showImmediateNotification(
      params['habitId'] as String,
      params['habitTitle'] as String,
      params['habitType'] as String,
    );
  }
  
  static Future<void> _showImmediateNotification(
    String habitId,
    String habitTitle,
    String habitType,
  ) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        _getMotivationalQuote(),
        contentTitle: '🔥 Time for: $habitTitle',
        summaryText: 'Tap to mark complete',
      ),
      actions: [
        const AndroidNotificationAction(
          'mark_done',
          '✅ Done',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'snooze',
          '⏰ Snooze 10min',
          showsUserInterface: false,
        ),
      ],
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      habitId.hashCode,
      '🔥 Time for: $habitTitle',
      _getMotivationalQuote(),
      notificationDetails,
      payload: habitId,
    );
  }
  
  static Future<void> cancelAlarm(String habitId) async {
    // Cancel all alarms for this habit (one for each day of week)
    for (int dayOfWeek = 0; dayOfWeek < 7; dayOfWeek++) {
      final alarmId = habitId.hashCode + dayOfWeek;
      await AndroidAlarmManager.cancel(alarmId);
      await _notifications.cancel(alarmId);
    }
  }
  
  static Future<void> cancelAllAlarms() async {
    // Note: AndroidAlarmManager doesn't have cancelAll method
    // Individual alarms need to be cancelled by ID
    await _notifications.cancelAll();
  }
  
  static int _generateAlarmId(String habitId, int dayOfWeek) {
    // Generate unique ID combining habit ID hash and day of week
    return (habitId.hashCode.abs() % 1000000) * 10 + dayOfWeek;
  }
  
  static Future<void> snoozeAlarm(String habitId, int minutes) async {
    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    final alarmId = habitId.hashCode.abs() % 1000000;
    
    await AndroidAlarmManager.oneShotAt(
      snoozeTime,
      alarmId + 9000000, // Different ID for snooze
      _alarmCallback,
      exact: true,
      wakeup: true,
      params: {
        'habitId': habitId,
        'habitTitle': 'Snoozed Reminder',
        'habitType': 'reminder',
      },
    );
  }
}
