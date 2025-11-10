import 'package:flutter/material.dart';

/// A habit system groups related habits together (e.g., "5AM Club", "75 Hard")
class HabitSystem {
  final String id;
  final String name;
  final String tagline;
  final int iconCodePoint; // Store as int to avoid non-const IconData issues
  final Color accentColor;
  final List<Color> gradientColors;
  final List<String> habitIds; // References to actual habit IDs
  final DateTime createdAt;
  
  HabitSystem({
    required this.id,
    required this.name,
    required this.tagline,
    required this.iconCodePoint,
    required this.accentColor,
    required this.gradientColors,
    required this.habitIds,
    required this.createdAt,
  });

  // REMOVED:
  // IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  // Models must not instantiate IconData in release builds (breaks tree-shaking)

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tagline': tagline,
    'iconCodePoint': iconCodePoint,
    'accentColorValue': accentColor.value,
    'gradientColorValues': gradientColors.map((c) => c.value).toList(),
    'habitIds': habitIds,
    'createdAt': createdAt.toIso8601String(),
  };
  
  // Create from JSON
  factory HabitSystem.fromJson(Map<String, dynamic> json) => HabitSystem(
    id: json['id'] as String,
    name: json['name'] as String,
    tagline: json['tagline'] as String,
    iconCodePoint: json['iconCodePoint'] as int,
    accentColor: Color(json['accentColorValue'] as int),
    gradientColors: (json['gradientColorValues'] as List<dynamic>)
        .map((v) => Color(v as int))
        .toList(),
    habitIds: (json['habitIds'] as List<dynamic>).cast<String>(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
  
  HabitSystem copyWith({
    String? id,
    String? name,
    String? tagline,
    int? iconCodePoint,
    Color? accentColor,
    List<Color>? gradientColors,
    List<String>? habitIds,
    DateTime? createdAt,
  }) => HabitSystem(
    id: id ?? this.id,
    name: name ?? this.name,
    tagline: tagline ?? this.tagline,
    iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    accentColor: accentColor ?? this.accentColor,
    gradientColors: gradientColors ?? this.gradientColors,
    habitIds: habitIds ?? this.habitIds,
    createdAt: createdAt ?? this.createdAt,
  );
}
