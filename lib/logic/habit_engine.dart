import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../services/local_storage.dart';
import '../services/api_client.dart';
import '../services/alarm_service.dart';
import '../services/streak_service.dart';

// Provider for the habit engine
final habitEngineProvider = StateNotifierProvider<HabitEngine, HabitEngineState>((ref) {
  return HabitEngine();
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
  static const Uuid _uuid = Uuid();
  final StreakService streakService = StreakService();
  
  HabitEngine() : super(const HabitEngineState()) {
    _loadHabits();
  }
  
  // Load habits from local storage
  Future<void> _loadHabits() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final habits = LocalStorageService.getAllHabits();
      state = state.copyWith(habits: habits, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
  
  // Public method to reload habits (for refresh)
  Future<void> reloadHabits() async {
    await _loadHabits();
  }
  
  // Create a new habit
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
        title: title,
        type: type,
        time: time,
        startDate: startDate ?? DateTime.now(),
        endDate: endDate ?? DateTime.now().add(const Duration(days: 365)),
        repeatDays: repeatDays ?? _getDefaultRepeatDays(type),
        createdAt: DateTime.now(),
      );
      
      // Save locally
      await LocalStorageService.saveHabit(habit);
      
      // Schedule alarm
      await AlarmService.scheduleAlarm(habit);
      
      // Reload from storage to ensure single source of truth
      await _loadHabits();
      state = state.copyWith(isLoading: false);
      
      print('✅ Habit created: ${habit.title}');
      print('📅 RepeatDays: ${habit.repeatDays}');
      print('📅 StartDate: ${habit.startDate}');
      print('📅 EndDate: ${habit.endDate}');
      print('📅 Total habits now: ${state.habits.length}');
      
      // Test if habit is scheduled for today
      final today = DateTime.now();
      final isScheduledToday = habit.isScheduledForDate(today);
      print('📅 Scheduled for today (${today.weekday}): $isScheduledToday');
      
      // Sync to backend (fire and forget)
      _syncHabitToBackend(habit);
      
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
  
  // Update an existing habit
  Future<void> updateHabit(Habit updatedHabit) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Save locally
      await LocalStorageService.saveHabit(updatedHabit);
      
      // Reschedule alarm
      await AlarmService.cancelAlarm(updatedHabit.id);
      await AlarmService.scheduleAlarm(updatedHabit);
      
      // Reload to reflect latest persisted state
      await _loadHabits();
      state = state.copyWith(isLoading: false);
      
      // Sync to backend (fire and forget)
      _syncHabitToBackend(updatedHabit);
      
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
  
  // Delete a habit
  Future<void> deleteHabit(String habitId) async {
    print('🗑️ Attempting to delete habit: $habitId');
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Find the habit first
      final habitToDelete = state.habits.firstWhere((h) => h.id == habitId);
      print('🗑️ Found habit to delete: ${habitToDelete.title}');
      
      // Delete locally
      await LocalStorageService.deleteHabit(habitId);
      print('🗑️ Deleted from local storage');
      
      // Cancel alarm (skip on non-Android platforms)
      try {
        await AlarmService.cancelAlarm(habitId);
        print('🗑️ Cancelled alarm');
      } catch (e) {
        print('🗑️ Skipped alarm cancel (not Android): $e');
      }
      
      // Reload to reflect removal
      await _loadHabits();
      state = state.copyWith(isLoading: false);
      
      print('🗑️ Habit deleted successfully: $habitId');
      print('📅 Total habits now: ${state.habits.length}');
      
      // Sync to backend (fire and forget)
      _deleteHabitFromBackend(habitId);
      
    } catch (e) {
      print('❌ Error deleting habit: $e');
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }
  
  // Toggle habit completion
  Future<void> toggleHabitCompletion(String habitId) async {
    final habit = state.habits.firstWhere((h) => h.id == habitId);
    final updatedHabit = habit.copyWith(
      done: !habit.done,
      completedAt: !habit.done ? DateTime.now() : null,
      streak: !habit.done ? habit.streak + 1 : habit.streak,
      xp: !habit.done ? habit.xp + _calculateXP(habit) : habit.xp,
    );
    
    await updateHabit(updatedHabit);
    
    // Log action to backend
    syncHabitCompletion(habitId, !habit.done);

    // Update streaks
    if (!habit.done) {
      await streakService.increment(xp: 15 + (updatedHabit.streak ~/ 7) * 5);
    }
  }
  
  // Sync habit completion to backend
  Future<void> syncHabitCompletion(String habitId, bool completed) async {
    try {
      await ApiClient.logAction(habitId, completed, DateTime.now());
    } catch (e) {
      // Silently fail - will be synced later
      print('Failed to sync habit completion: $e');
    }
  }
  
  // Sync all habits to backend
  Future<void> syncAllHabits() async {
    state = state.copyWith(isSyncing: true);
    
    try {
      final response = await ApiClient.syncAll(state.habits);
      
      if (response.success && response.data != null) {
        // Update local storage with server data
        for (final habit in response.data!.updatedHabits) {
          await LocalStorageService.saveHabit(habit);
        }
        
        // Delete habits that were deleted on server
        for (final habitId in response.data!.deletedHabitIds) {
          await LocalStorageService.deleteHabit(habitId);
          await AlarmService.cancelAlarm(habitId);
        }
        
        // Reload habits
        await _loadHabits();
      }
    } catch (e) {
      state = state.copyWith(error: 'Sync failed: $e');
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }
  
  // Get habits for a specific date
  List<Habit> getHabitsForDate(DateTime date) {
    return state.habits.where((habit) => habit.isScheduledForDate(date)).toList();
  }
  
  // Get today's habits
  List<Habit> getTodayHabits() {
    return getHabitsForDate(DateTime.now());
  }
  
  // Calculate fulfillment percentage for a date
  double getFulfillmentPercentage(DateTime date) {
    final dayHabits = getHabitsForDate(date);
    if (dayHabits.isEmpty) return 0.0;
    
    final completedCount = dayHabits.where((habit) => habit.done).length;
    return (completedCount / dayHabits.length) * 100;
  }
  
  // Calculate current streak
  int getCurrentStreak() {
    return LocalStorageService.calculateCurrentStreak();
  }
  
  // Calculate longest streak
  int getLongestStreak() {
    return LocalStorageService.calculateLongestStreak();
  }
  
  // Private helper methods
  List<int> _getDefaultRepeatDays(String type) {
    if (type == 'habit') {
      return [1, 2, 3, 4, 5]; // Weekdays
    } else {
      return [DateTime.now().weekday % 7]; // Today only for tasks
    }
  }
  
  int _calculateXP(Habit habit) {
    // Base XP
    int xp = 10;
    
    // Bonus for streaks
    if (habit.streak > 0) {
      xp += (habit.streak / 7).floor() * 5; // +5 XP per week of streak
    }
    
    // Bonus for habit type
    if (habit.type == 'habit') {
      xp += 5; // Habits are worth more than tasks
    }
    
    return xp;
  }
  
  Future<void> _syncHabitToBackend(Habit habit) async {
    try {
      await ApiClient.createHabit(habit);
    } catch (e) {
      // Silently fail - will be synced later
      print('Failed to sync habit to backend: $e');
    }
  }
  
  Future<void> _deleteHabitFromBackend(String habitId) async {
    try {
      await ApiClient.deleteHabit(habitId);
    } catch (e) {
      // Silently fail - will be synced later
      print('Failed to delete habit from backend: $e');
    }
  }
  
  // Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Utility providers
final todayHabitsProvider = Provider<List<Habit>>((ref) {
  final habitEngine = ref.watch(habitEngineProvider);
  return habitEngine.habits.where((habit) => habit.isScheduledForToday()).toList();
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
