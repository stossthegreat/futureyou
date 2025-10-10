import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';

class LocalStorageService {
  static const String _habitsBoxName = 'habits';
  static const String _settingsBoxName = 'settings';

  static Box<Habit>? _habitsBox;
  static Box? _settingsBox;

  // -------------------- INITIALIZATION --------------------
  static Future<void> initialize() async {
    _habitsBox = await Hive.openBox<Habit>(_habitsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  // -------------------- CRUD OPERATIONS --------------------
  static Future<void> saveHabit(Habit habit) async {
    await _habitsBox?.put(habit.id, habit);
  }

  static Future<void> deleteHabit(String id) async {
    await _habitsBox?.delete(id);
  }

  static Habit? getHabit(String id) => _habitsBox?.get(id);

  static List<Habit> getAllHabits() =>
      _habitsBox?.values.toList() ?? [];

  // ✅ FIXED: robust date filtering that respects startDate, endDate, and repeatDays
  static List<Habit> getHabitsForDate(DateTime date) {
    final allHabits = getAllHabits();

    return allHabits.where((habit) {
      // Let the Habit model handle base scheduling
      final isScheduled = habit.isScheduledForDate(date);
      if (!isScheduled) return false;

      final dateOnly = DateTime(date.year, date.month, date.day);
      final startOnly = DateTime(habit.startDate.year, habit.startDate.month, habit.startDate.day);
      final endOnly = DateTime(habit.endDate.year, habit.endDate.month, habit.endDate.day);

      // 🧠 Habits: show between start and end
      if (habit.type == 'habit') {
        return !dateOnly.isBefore(startOnly) && !dateOnly.isAfter(endOnly);
      }

      // 📅 Tasks: show only on the exact start date
      if (habit.type == 'task') {
        return dateOnly.isAtSameMomentAs(startOnly);
      }

      return false;
    }).toList();
  }

  static List<Habit> getTodayHabits() =>
      getHabitsForDate(DateTime.now());

  // -------------------- UPDATES --------------------
  static Future<void> updateHabitCompletion(String id, bool done) async {
    final habit = getHabit(id);
    if (habit == null) return;
    final updated = habit.copyWith(
      done: done,
      completedAt: done ? DateTime.now() : null,
    );
    await saveHabit(updated);
  }

  static Future<void> clearAllHabits() async =>
      _habitsBox?.clear();

  // -------------------- SETTINGS --------------------
  static Future<void> saveSetting(String key, dynamic value) async =>
      _settingsBox?.put(key, value);

  static T? getSetting<T>(String key, {T? defaultValue}) =>
      _settingsBox?.get(key, defaultValue: defaultValue) as T?;

  static Future<void> deleteSetting(String key) async =>
      _settingsBox?.delete(key);

  static Future<void> clearAllSettings() async =>
      _settingsBox?.clear();

  // -------------------- STREAKS & ANALYTICS --------------------
  static int calculateCurrentStreak() {
    final habits = getAllHabits();
    if (habits.isEmpty) return 0;
    int streak = 0;
    final today = DateTime.now();

    // Go backwards up to 365 days
    for (int i = 0; i < 365; i++) {
      final checkDate = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: i));

      final dayHabits =
          habits.where((h) => h.isScheduledForDate(checkDate)).toList();
      if (dayHabits.isEmpty) continue;

      final allCompleted =
          dayHabits.every((h) => h.isDoneOn(checkDate));

      if (allCompleted) streak++;
      else break;
    }
    return streak;
  }

  static int calculateLongestStreak() {
    final habits = getAllHabits();
    if (habits.isEmpty) return 0;

    int longest = 0, current = 0;
    DateTime? earliest;

    // Find earliest start date
    for (final h in habits) {
      earliest ??= h.startDate;
      if (h.startDate.isBefore(earliest)) earliest = h.startDate;
    }

    if (earliest == null) return 0;

    final days = DateTime.now().difference(earliest).inDays;

    for (int i = 0; i <= days; i++) {
      final d = DateTime(
        earliest.year,
        earliest.month,
        earliest.day + i,
      );

      final dayHabits =
          habits.where((h) => h.isScheduledForDate(d)).toList();
      if (dayHabits.isEmpty) {
        current = 0;
        continue;
      }

      final allCompleted =
          dayHabits.every((h) => h.isDoneOn(d));

      if (allCompleted) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 0;
      }
    }

    return longest;
  }

  static double getFulfillmentPercentage(DateTime date) {
    final dayHabits =
        getAllHabits().where((h) => h.isScheduledForDate(date)).toList();
    if (dayHabits.isEmpty) return 0.0;

    final completedCount =
        dayHabits.where((h) => h.isDoneOn(date)).length;

    return (completedCount / dayHabits.length) * 100;
  }

  static double getTodayFulfillmentPercentage() =>
      getFulfillmentPercentage(DateTime.now());

  static double getDriftPercentage(DateTime date) =>
      100 - getFulfillmentPercentage(date);

  static double getTodayDriftPercentage() =>
      getDriftPercentage(DateTime.now());
}
