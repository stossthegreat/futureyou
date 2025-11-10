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
  }

  Future<void> addHabit(Habit h) async {
    await LocalStorageService.saveHabit(h);
    _habits.add(h);
    notifyListeners();

    // Only schedule alarm if explicitly turned on
    if (h.reminderOn) {
      await _scheduleNext(h);
    }
  }

  Future<void> deleteHabit(String id) async {
    await LocalStorageService.deleteHabit(id);
    _habits.removeWhere((x) => x.id == id);
    notifyListeners();
    await AlarmService.cancelAlarm(id);
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

  // 🔔 Schedule next alarm using AlarmService
  Future<void> _scheduleNext(Habit h) async {
    await AlarmService.scheduleAlarm(h);
    if (kDebugMode) {
      print('✅ Scheduled alarm for ${h.title}');
    }
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
    bool reminderOn = false, // default OFF
    String? systemId, // NEW: Link to parent system
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
      emoji: emoji,
      reminderOn: reminderOn,
      systemId: systemId, // NEW: Set systemId
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
      xp: nowDone ? habit.xp + 15 : habit.xp,
    );

    await LocalStorageService.saveHabit(updated);
    final idx = _habits.indexWhere((h) => h.id == habitId);
    if (idx != -1) {
      _habits[idx] = updated;
      notifyListeners();
    }

    // Sync completion to backend (observer pattern)
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

      // Queue for sync service to handle
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
