import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/habit.dart';
import '../services/local_storage.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class HabitEngine extends ChangeNotifier {
  final LocalStorageService localStorageService;
  List<Habit> _habits = [];
  bool _isSyncing = false;
  
  List<Habit> get habits => _habits;
  bool get isSyncing => _isSyncing;
  
  // Calculate current streak (consecutive days of habit completion)
  int get currentStreak {
    if (_habits.isEmpty) return 0;
    
    final today = DateTime.now();
    int streak = 0;
    
    for (int i = 0; i >= -30; i--) { // Check last 30 days
      final checkDate = today.add(Duration(days: i));
      final scheduledHabits = _habits.where((h) => h.isScheduledForDate(checkDate)).toList();
      
      if (scheduledHabits.isEmpty) continue;
      
      final completedCount = scheduledHabits.where((h) => h.isDoneOn(checkDate)).length;
      final totalCount = scheduledHabits.length;
      
      if (completedCount == totalCount && totalCount > 0) {
        streak++;
      } else if (i < 0) { // Only break streak for past days, not today
        break;
      }
    }
    
    return streak;
  }
  
  // Calculate longest streak ever
  int get longestStreak {
    if (_habits.isEmpty) return 0;
    
    int maxStreak = 0;
    int currentStreakCount = 0;
    final today = DateTime.now();
    
    // Check last 365 days
    for (int i = -365; i <= 0; i++) {
      final checkDate = today.add(Duration(days: i));
      final scheduledHabits = _habits.where((h) => h.isScheduledForDate(checkDate)).toList();
      
      if (scheduledHabits.isEmpty) continue;
      
      final completedCount = scheduledHabits.where((h) => h.isDoneOn(checkDate)).length;
      final totalCount = scheduledHabits.length;
      
      if (completedCount == totalCount && totalCount > 0) {
        currentStreakCount++;
        maxStreak = maxStreak > currentStreakCount ? maxStreak : currentStreakCount;
      } else {
        currentStreakCount = 0;
      }
    }
    
    return maxStreak;
  }
  
  // Calculate total XP from all habits
  int get totalXP => _habits.fold(0, (sum, habit) => sum + habit.xp);
  
  HabitEngine(this.localStorageService);
  
  Future<void> loadHabits() async {
    _habits = LocalStorageService.getAllHabits();
    notifyListeners(); // ensures UI updates immediately
  }
  
  Future<void> addHabit(Habit h) async {
    await LocalStorageService.saveHabit(h);
    _habits.add(h);
    notifyListeners(); // ✅ fix 1: new habit appears instantly
    await _scheduleNext(h); // ✅ fix 2+3: schedule next valid alarm
  }
  
  Future<void> deleteHabit(String id) async {
    await LocalStorageService.deleteHabit(id);
    _habits.removeWhere((x) => x.id == id);
    notifyListeners();
    await flutterLocalNotificationsPlugin.cancel(id.hashCode);
  }
  
  Future<void> completeHabit(String id) async {
    final idx = _habits.indexWhere((x) => x.id == id);
    if (idx == -1) return;
    
    final h = _habits[idx];
    final updated = h.copyWith(
      done: true,
      completedAt: DateTime.now(),
      streak: h.streak + 1,
      xp: h.xp + 15, // Add 15 XP per completed habit
    );
    
    await LocalStorageService.saveHabit(updated);
    _habits[idx] = updated;
    notifyListeners();
  }
  
  /// -----------------------
  /// Scheduling
  /// -----------------------
  Future<void> _scheduleNext(Habit h) async {
    if (h.repeatDays.isEmpty) return;
    
    final start = h.startDate;
    final next = _nextOccurrence(start, h.repeatDays, h.timeOfDay);
    
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'futureyou_channel',
        'Future You OS',
        channelDescription: 'Habit reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      ),
    );
    
    await flutterLocalNotificationsPlugin.zonedSchedule(
      h.id.hashCode,
      'Future You OS',
      '${h.title} is due now',
      tz.TZDateTime.from(next, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    
    if (kDebugMode) {
      print('✅ Scheduled ${h.title} for $next');
    }
  }
  
  DateTime _nextOccurrence(DateTime start, List<int> repeatDays, TimeOfDay? time) {
    final now = DateTime.now();
    final base = DateTime(
      now.year, 
      now.month, 
      now.day, 
      time?.hour ?? start.hour, 
      time?.minute ?? start.minute
    );
    
    for (int i = 0; i < 7; i++) {
      final candidate = base.add(Duration(days: i));
      final weekday = (candidate.weekday % 7); // Mon=1..Sun=7 → 0..6
      if (repeatDays.contains(weekday) && candidate.isAfter(now)) {
        return candidate;
      }
    }
    
    // fallback → tomorrow
    return base.add(const Duration(days: 1));
  }
  
  // Helper methods for compatibility with existing code
  Future<void> createHabit({
    required String title,
    required String type,
    required String time,
    DateTime? startDate,
    DateTime? endDate,
    List<int>? repeatDays,
    Color? color,
  }) async {
    final habit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      type: type,
      time: time,
      startDate: startDate ?? DateTime.now(),
      endDate: endDate ?? DateTime.now().add(const Duration(days: 365)),
      repeatDays: repeatDays ?? _getDefaultRepeatDays(type),
      createdAt: DateTime.now(),
      colorValue: color?.value ?? 0xFF10B981,
    );
    
    await addHabit(habit);
  }
  
  Future<void> toggleHabitCompletion(String habitId) async {
    final habit = _habits.firstWhere((h) => h.id == habitId);
    final today = DateTime.now();
    final isCurrentlyDone = habit.isDoneOn(today);
    final nowDone = !isCurrentlyDone;
    
    final updated = habit.copyWith(
      done: nowDone,
      completedAt: nowDone ? today : null,
      streak: nowDone ? habit.streak + 1 : 0,
      xp: nowDone ? habit.xp + 15 : habit.xp, // Add 15 XP when completing
    );

    await LocalStorageService.saveHabit(updated);
    final idx = _habits.indexWhere((h) => h.id == habitId);
    if (idx != -1) {
      _habits[idx] = updated;
      notifyListeners();
    }
  }
  
  List<int> _getDefaultRepeatDays(String type) =>
      type == 'habit' ? [1, 2, 3, 4, 5] : [DateTime.now().weekday % 7];
  
  // Sync method for compatibility
  Future<void> syncAllHabits() async {
    _isSyncing = true;
    notifyListeners();
    
    try {
      // For now, just reload habits - you can implement actual sync later
      await loadHabits();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
