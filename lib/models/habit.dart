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
  List<int> repeatDays; // 0=Sun...6=Sat

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

  // Helper methods
  TimeOfDay get timeOfDay {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  bool isScheduledForDate(DateTime date) {
    // Check if date is within range
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
    
    if (dateOnly.isBefore(startOnly) || dateOnly.isAfter(endOnly)) {
      return false;
    }

    // Check if weekday matches repeatDays
    // Dart: Monday=1, Tuesday=2, ..., Sunday=7
    // Our system: Sunday=0, Monday=1, ..., Saturday=6
    final weekday = date.weekday == 7 ? 0 : date.weekday; // Convert Sunday from 7 to 0
    return repeatDays.contains(weekday);
  }

  bool isScheduledForToday() {
    return isScheduledForDate(DateTime.now());
  }

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

  Map<String, dynamic> toJson() {
    return {
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
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
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
}
