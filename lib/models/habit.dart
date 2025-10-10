import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'habit.g.dart';

@HiveType(typeId: 0)
class Habit extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String type; // 'habit' or 'task'

  @HiveField(3)
  String time; // "HH:mm" format

  @HiveField(4)
  DateTime startDate;

  @HiveField(5)
  DateTime endDate;

  @HiveField(6)
  List<int> repeatDays; // 0 = Sun ... 6 = Sat

  @HiveField(7)
  bool done;

  @HiveField(8)
  bool reminderOn;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime? completedAt;

  @HiveField(11)
  int streak;

  @HiveField(12)
  int xp;

  Habit({
    required this.id,
    required this.title,
    required this.type,
    required this.time,
    required this.startDate,
    required this.endDate,
    required this.repeatDays,
    this.done = false,
    this.reminderOn = true,
    required this.createdAt,
    this.completedAt,
    this.streak = 0,
    this.xp = 0,
  });

  /// Returns TimeOfDay object for convenience
  TimeOfDay get timeOfDay {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  // ----------------------------------------------------
  // 🔥 CORE SCHEDULING LOGIC
  // ----------------------------------------------------

  /// Determines if this habit/task is active on a given date.
  bool isScheduledForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);

    // 1️⃣ Range check
    if (dateOnly.isBefore(startOnly) || dateOnly.isAfter(endOnly)) {
      return false;
    }

    // 2️⃣ TASK: single-day execution only
    if (type == 'task') {
      return dateOnly.isAtSameMomentAs(startOnly);
    }

    // 3️⃣ HABIT: weekly repeating logic
    int weekday0to6 = date.weekday % 7; // Dart: Mon=1..Sun=7 → 1..0
    if (weekday0to6 == 0) weekday0to6 = 0; // Sunday fix

    // Daily fallback if list empty
    if (repeatDays.isEmpty) return true;

    // Match repeat days
    if (repeatDays.contains(weekday0to6)) {
      return true;
    }

    // 4️⃣ OPTIONAL — support "Every N days" (future use)
    if (repeatDays.length == 1 && repeatDays.first == -1) {
      final diff = dateOnly.difference(startOnly).inDays;
      final interval = xp > 0 ? xp : 2; // reuse XP as interval
      return diff % interval == 0;
    }

    return false;
  }

  bool isScheduledForToday() => isScheduledForDate(DateTime.now());

  /// Checks if marked done on a specific date
  bool isDoneOn(DateTime date) {
    if (completedAt == null) return false;
    final d = DateTime(date.year, date.month, date.day);
    final c = DateTime(completedAt!.year, completedAt!.month, completedAt!.day);
    return d.isAtSameMomentAs(c);
  }

  // ----------------------------------------------------
  // 🧩 HELPERS & SERIALIZATION
  // ----------------------------------------------------

  Habit copyWith({
    String? id,
    String? title,
    String? type,
    String? time,
    DateTime? startDate,
    DateTime? endDate,
    List<int>? repeatDays,
    bool? done,
    bool? reminderOn,
    DateTime? createdAt,
    DateTime? completedAt,
    int? streak,
    int? xp,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      time: time ?? this.time,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      repeatDays: repeatDays ?? this.repeatDays,
      done: done ?? this.done,
      reminderOn: reminderOn ?? this.reminderOn,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      streak: streak ?? this.streak,
      xp: xp ?? this.xp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'time': time,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'repeatDays': repeatDays,
        'done': done,
        'reminderOn': reminderOn,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'streak': streak,
        'xp': xp,
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'],
        title: json['title'],
        type: json['type'],
        time: json['time'],
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        repeatDays: List<int>.from(json['repeatDays']),
        done: json['done'] ?? false,
        reminderOn: json['reminderOn'] ?? true,
        createdAt: DateTime.parse(json['createdAt']),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'])
            : null,
        streak: json['streak'] ?? 0,
        xp: json['xp'] ?? 0,
      );
}
