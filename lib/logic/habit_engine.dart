import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/local_storage.dart';
import '../services/sync_service.dart';
import '../services/api_client.dart';
import '../services/alarm_service.dart';

class HabitEngine extends ChangeNotifier {
  final LocalStorageService localStorageService;
  List<Habit> _habits = [];
  bool _isSyncing = false;

  List<Habit> get habits => _habits;
  bool get isSyncing => _isSyncing;

  HabitEngine(this.localStorageService);

  Future<void> loadHabits() async {
    _habits = LocalStorageService.getAllHabits();
    notifyListeners();
    debugPrint('✅ Loaded ${_habits.length} habits');
  }

  Future<void> addHabit(Habit h) async {
    await LocalStorageService.saveHabit(h);
    _habits.add(h);
    notifyListeners();

    // Schedule alarm if reminder is enabled
    if (h.reminderOn && h.time.isNotEmpty) {
      try {
        await AlarmService.scheduleAlarm(h);
        debugPrint('✅ Alarm scheduled successfully for habit: ${h.title}');
      } catch (e) {
        debugPrint('⚠️ Failed to schedule alarm for habit "${h.title}": $e');
      }
    } else {
      debugPrint('⏰ No alarm scheduled for "${h.title}" (reminderOn=${h.reminderOn}, time="${h.time}")');
    }
  }

  Future<void> deleteHabit(String id) async {
    await LocalStorageService.deleteHabit(id);
    _habits.removeWhere((x) => x.id == id);
    notifyListeners();
    await AlarmService.cancelAlarm(id);
    debugPrint('🗑️ Deleted habit and cancelled alarms: $id');
  }

  Future<void> completeHabit(String id) async {
    final idx = _habits.indexWhere((x) => x.id == id);
    if (idx == -1) return;

    final h = _habits[idx];
    final updated = h.copyWith(
      done: true,
      completedAt: DateTime.now(),
      streak: h.streak + 1,
      xp: h.xp + 15,
    );

    await LocalStorageService.saveHabit(updated);
    _habits[idx] = updated;
    notifyListeners();
  }

  Future<void> createHabit({
    required String title,
    required String type,
    required String time,
    DateTime? startDate,
    DateTime? endDate,
    List<int>? repeatDays,
    Color? color,
    String? emoji,
    bool reminderOn = false,
    String? systemId,
  }) async {
    // CRITICAL DEBUG LOGGING
    debugPrint('═══════════════════════════════════════');
    debugPrint('🔍 createHabit called:');
    debugPrint('   - title: "$title"');
    debugPrint('   - type: "$type"');
    debugPrint('   - time: "$time"');
    debugPrint('   - reminderOn: $reminderOn');
    debugPrint('   - repeatDays: $repeatDays');
    debugPrint('   - systemId: $systemId');
    debugPrint('═══════════════════════════════════════');

    // Validate: Don't create alarm if no time set
    bool finalReminderOn = reminderOn;
    if (reminderOn && time.isEmpty) {
      debugPrint('⚠️ WARNING: reminderOn=true but time is EMPTY! Disabling alarm.');
      finalReminderOn = false;
    }

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
      emoji: emoji,
      reminderOn: finalReminderOn,
      systemId: systemId,
    );

    debugPrint('✅ Habit object created:');
    debugPrint('   - id: ${habit.id}');
    debugPrint('   - title: "${habit.title}"');
    debugPrint('   - time: "${habit.time}"');
    debugPrint('   - reminderOn: ${habit.reminderOn}');
    debugPrint('   - repeatDays: ${habit.repeatDays}');

    await addHabit(habit);

    // Verify alarm scheduling
    if (habit.reminderOn) {
      debugPrint('✅✅✅ Alarm SHOULD be scheduled for "${habit.title}"');
    } else {
      debugPrint('⏰⏰⏰ Alarm NOT scheduled (reminderOn=false)');
    }
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
      xp: nowDone ? habit.xp + 15 : habit.xp,
    );

    await LocalStorageService.saveHabit(updated);
    final idx = _habits.indexWhere((h) => h.id == habitId);
    if (idx != -1) {
      _habits[idx] = updated;
      notifyListeners();
    }

    // Sync completion to backend
    _syncCompletionToBackend(habitId, nowDone, today);
  }

  /// Sync habit completion to backend as observer event
  void _syncCompletionToBackend(String habitId, bool done, DateTime date) {
    try {
      final completion = HabitCompletion(
        habitId: habitId,
        date: date,
        done: done,
        completedAt: done ? DateTime.now() : null,
      );

      syncService.queueCompletion(completion);
      debugPrint('📤 Queued completion for sync: $habitId (${done ? "done" : "undone"})');
    } catch (e) {
      debugPrint('❌ Failed to queue completion: $e');
    }
  }

  List<int> _getDefaultRepeatDays(String type) =>
      type == 'habit' ? [1, 2, 3, 4, 5] : [DateTime.now().weekday % 7];

  Future<void> syncAllHabits() async {
    _isSyncing = true;
    notifyListeners();

    try {
      await loadHabits();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
