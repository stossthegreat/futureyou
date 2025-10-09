import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';

class LocalStorageService {
  static const String _habitsBoxName = 'habits';
  static const String _settingsBoxName = 'settings';
  
  static Box<Habit>? _habitsBox;
  static Box? _settingsBox;
  
  static Future<void> initialize() async {
    _habitsBox = await Hive.openBox<Habit>(_habitsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }
  
  // Habits CRUD operations
  static Future<void> saveHabit(Habit habit) async {
    await _habitsBox?.put(habit.id, habit);
  }
  
  static Future<void> deleteHabit(String id) async {
    await _habitsBox?.delete(id);
  }
  
  static Habit? getHabit(String id) {
    return _habitsBox?.get(id);
  }
  
  static List<Habit> getAllHabits() {
    return _habitsBox?.values.toList() ?? [];
  }
  
  static List<Habit> getHabitsForDate(DateTime date) {
    final allHabits = getAllHabits();
    return allHabits.where((habit) => habit.isScheduledForDate(date)).toList();
  }
  
  static List<Habit> getTodayHabits() {
    return getHabitsForDate(DateTime.now());
  }
  
  static Future<void> updateHabitCompletion(String id, bool done) async {
    final habit = getHabit(id);
    if (habit != null) {
      final updatedHabit = habit.copyWith(
        done: done,
        completedAt: done ? DateTime.now() : null,
      );
      await saveHabit(updatedHabit);
    }
  }
  
  static Future<void> clearAllHabits() async {
    await _habitsBox?.clear();
  }
  
  // Settings operations
  static Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox?.put(key, value);
  }
  
  static T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox?.get(key, defaultValue: defaultValue) as T?;
  }
  
  static Future<void> deleteSetting(String key) async {
    await _settingsBox?.delete(key);
  }
  
  static Future<void> clearAllSettings() async {
    await _settingsBox?.clear();
  }
  
  // Streak calculations
  static int calculateCurrentStreak() {
    final habits = getAllHabits();
    if (habits.isEmpty) return 0;
    
    int streak = 0;
    final today = DateTime.now();
    
    // Check consecutive days backwards from today
    for (int i = 0; i < 365; i++) { // Max 365 days check
      final checkDate = DateTime(
        today.year,
        today.month,
        today.day - i,
      );
      
      final dayHabits = getHabitsForDate(checkDate);
      if (dayHabits.isEmpty) continue;
      
      final allCompleted = dayHabits.every((habit) => habit.done);
      if (allCompleted) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }
  
  static int calculateLongestStreak() {
    final habits = getAllHabits();
    if (habits.isEmpty) return 0;
    
    int longestStreak = 0;
    int currentStreak = 0;
    final today = DateTime.now();
    
    // Check all days from earliest habit to today
    DateTime? earliestDate;
    for (final habit in habits) {
      if (earliestDate == null || habit.startDate.isBefore(earliestDate)) {
        earliestDate = habit.startDate;
      }
    }
    
    if (earliestDate == null) return 0;
    
    final daysDiff = today.difference(earliestDate).inDays;
    
    for (int i = 0; i <= daysDiff; i++) {
      final checkDate = DateTime(
        earliestDate.year,
        earliestDate.month,
        earliestDate.day + i,
      );
      
      final dayHabits = getHabitsForDate(checkDate);
      if (dayHabits.isEmpty) {
        currentStreak = 0;
        continue;
      }
      
      final allCompleted = dayHabits.every((habit) => habit.done);
      if (allCompleted) {
        currentStreak++;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
      } else {
        currentStreak = 0;
      }
    }
    
    return longestStreak;
  }
  
  // Analytics
  static double getFulfillmentPercentage(DateTime date) {
    final dayHabits = getHabitsForDate(date);
    if (dayHabits.isEmpty) return 0.0;
    
    final completedCount = dayHabits.where((habit) => habit.done).length;
    return (completedCount / dayHabits.length) * 100;
  }
  
  static double getTodayFulfillmentPercentage() {
    return getFulfillmentPercentage(DateTime.now());
  }
  
  static double getDriftPercentage(DateTime date) {
    return 100 - getFulfillmentPercentage(date);
  }
  
  static double getTodayDriftPercentage() {
    return getDriftPercentage(DateTime.now());
  }
}
