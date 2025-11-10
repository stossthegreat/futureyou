import 'package:flutter/material.dart';

/// A habit system groups related habits together (e.g., "5AM Club", "75 Hard")
class HabitSystem {
  final String id;
  final String name;
  final String tagline;
  final IconData icon;
  final Color accentColor;
  final List<Color> gradientColors;
  final List<String> habitIds; // References to actual habit IDs
  final DateTime createdAt;
  
  HabitSystem({
    required this.id,
    required this.name,
    required this.tagline,
    required this.icon,
    required this.accentColor,
    required this.gradientColors,
    required this.habitIds,
    required this.createdAt,
  });
  
  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tagline': tagline,
    'iconCodePoint': icon.codePoint,
    'accentColorValue': accentColor.value,
    'gradientColorValues': gradientColors.map((c) => c.value).toList(),
    'habitIds': habitIds,
    'createdAt': createdAt.toIso8601String(),
  };
  
  // Create from JSON
  factory HabitSystem.fromJson(Map<String, dynamic> json) {
    final int codePoint = json['iconCodePoint'] as int;
    return HabitSystem(
      id: json['id'] as String,
      name: json['name'] as String,
      tagline: json['tagline'] as String,
      icon: IconData(codePoint, fontFamily: 'MaterialIcons'),
      accentColor: Color(json['accentColorValue'] as int),
      gradientColors: (json['gradientColorValues'] as List<dynamic>)
          .map((v) => Color(v as int))
          .toList(),
      habitIds: (json['habitIds'] as List<dynamic>).cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
  
  HabitSystem copyWith({
    String? id,
    String? name,
    String? tagline,
    IconData? icon,
    Color? accentColor,
    List<Color>? gradientColors,
    List<String>? habitIds,
    DateTime? createdAt,
  }) => HabitSystem(
    id: id ?? this.id,
    name: name ?? this.name,
    tagline: tagline ?? this.tagline,
    icon: icon ?? this.icon,
    accentColor: accentColor ?? this.accentColor,
    gradientColors: gradientColors ?? this.gradientColors,
    habitIds: habitIds ?? this.habitIds,
    createdAt: createdAt ?? this.createdAt,
  );
}

