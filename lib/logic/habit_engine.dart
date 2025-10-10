import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../services/local_storage.dart';
import '../services/api_client.dart';
import '../services/alarm_service.dart';
import '../services/streak_service.dart';

final habitEngineProvider =
    StateNotifierProvider<HabitEngine, HabitEngineState>((ref) {
  return HabitEngine(ref);
});

class HabitEngineState {
  final List<Habit> habits;
  final bool isLoading;
  final String? error;
  final bool isSyncing;

  const HabitEngineState({
    this.habits = const [],
    this.isLoading = false,
    this.error,
    this.isSyncing = false,
  });

  HabitEngineState copyWith({
    List<Habit>? habits,
    bool? isLoading,
    String? error,
    bool? isSyncing,
  }) {
    return HabitEngineState(
      habits: habits ?? this.habits,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

class HabitEngine extends StateNotifier<HabitEngineState> {
  final Ref ref;
  static const Uuid _uuid = Uuid();

  HabitEngine(this.ref) : super(const HabitEngineState()) {
    _loadHabits();
  }

  // -------------------- LOAD --------------------
  Future<void> _loadHabits() async {
    try {
      final habits = LocalStorageService.getAllHabits();
      state = state.copyWith(habits: habits, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> reloadHabits() async => _loadHabits();

  // -------------------- CREATE --------------------
  Future<void> createHabit({
    required String title,
    required String type,
    required String time,
    DateTime? startDate,
    DateTime? endDate,
    List<int>? repeatDays,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final habit = Habit(
        id: _uuid.v4(),
        title: title.trim(),
        type: type,
        time: time,
        startDate: startDate ?? DateTime.now(),
        endDate: endDate ?? DateTime.now().add(const Duration(days: 365)),
        repeatDays: repeatDays ?? _getDefaultRepeatDays(type),
        createdAt: DateTime.now(),
      );

      await LocalStorageService.saveHabit(habit);
      await AlarmService.scheduleAlarm(habit);

      await _loadHabits();
      state = state.copyWith(isLoading: false);
      _syncHabitToBackend(habit);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // -------------------- UPDATE --------------------
  Future<void> updateHabit(Habit updatedHabit) async {
    try {
      await LocalStorageService.saveHabit(updatedHabit);
      await AlarmService.cancelAlarm(updatedHabit.id);
      await AlarmService.scheduleAlarm(updatedHabit);
      await _loadHabits();
      _syncHabitToBackend(updatedHabit);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // -------------------- DELETE --------------------
  Future<void> deleteHabit(String habitId) async {
    try {
      await LocalStorageService.deleteHabit(habitId);
      await AlarmService.cancelAlarm(habitId);
      await _loadHabits();
      _deleteHabitFromBackend(habitId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // -------------------- TOGGLE COMPLETION --------------------
  Future<void> toggleHabitCompletion(String habitId) async {
    final habit = state.habits.firstWhere((h) => h.id == habitId);
    final nowDone = !habit.done;
    final updated = habit.copyWith(
      done: nowDone,
      completedAt: nowDone ? DateTime.now() : null,
      streak: nowDone ? habit.streak + 1 : 0,
      xp: nowDone ? habit.xp + _calculateXP(habit) : habit.xp,
    );

    await LocalStorageService.saveHabit(updated);
    await _loadHabits();

    // update streak service
    final streakService = ref.read(streakServiceProvider.notifier);
    streakService.refreshStreaks();

    // backend
    syncHabitCompletion(habitId, nowDone);
  }

  Future<void> syncHabitCompletion(String habitId, bool completed) async {
    try {
      await ApiClient.logAction(habitId, completed, DateTime.now());
    } catch (e) {
      // Log error silently in production
    }
  }

  // -------------------- SYNC ALL --------------------
  Future<void> syncAllHabits() async {
    state = state.copyWith(isSyncing: true);
    try {
      final response = await ApiClient.syncAll(state.habits);
      if (response.success && response.data != null) {
        for (final h in response.data!.updatedHabits) {
          await LocalStorageService.saveHabit(h);
        }
        for (final id in response.data!.deletedHabitIds) {
          await LocalStorageService.deleteHabit(id);
          await AlarmService.cancelAlarm(id);
        }
        await _loadHabits();
      }
    } catch (e) {
      state = state.copyWith(error: 'Sync failed: $e');
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  // -------------------- GETTERS --------------------
  List<Habit> getHabitsForDate(DateTime date) =>
      state.habits.where((h) => h.isScheduledForDate(date)).toList();

  List<Habit> getTodayHabits() => getHabitsForDate(DateTime.now());

  double getFulfillmentPercentage(DateTime date) {
    final dayHabits = getHabitsForDate(date);
    if (dayHabits.isEmpty) return 0;
    final doneCount = dayHabits.where((h) => h.isDoneOn(date)).length;
    return (doneCount / dayHabits.length) * 100;
  }

  int getCurrentStreak() => LocalStorageService.calculateCurrentStreak();

  int getLongestStreak() => LocalStorageService.calculateLongestStreak();

  // -------------------- HELPERS --------------------
  List<int> _getDefaultRepeatDays(String type) =>
      type == 'habit' ? [1, 2, 3, 4, 5] : [DateTime.now().weekday % 7];

  int _calculateXP(Habit habit) {
    int xp = 10;
    xp += (habit.streak ~/ 7) * 5;
    if (habit.type == 'habit') xp += 5;
    return xp;
  }

  Future<void> _syncHabitToBackend(Habit habit) async {
    try {
      await ApiClient.createHabit(habit);
    } catch (e) {
      // Log error silently in production
    }
  }

  Future<void> _deleteHabitFromBackend(String id) async {
    try {
      await ApiClient.deleteHabit(id);
    } catch (e) {
      // Log error silently in production
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

// -------------- PROVIDERS --------------

final todayHabitsProvider = Provider<List<Habit>>((ref) {
  final engine = ref.watch(habitEngineProvider);
  return engine.habits
      .where((h) => h.isScheduledForToday())
      .toList();
});

final currentStreakProvider = Provider<int>((ref) {
  return LocalStorageService.calculateCurrentStreak();
});

final longestStreakProvider = Provider<int>((ref) {
  return LocalStorageService.calculateLongestStreak();
});

final todayFulfillmentProvider = Provider<double>((ref) {
  return LocalStorageService.getTodayFulfillmentPercentage();
});
