import 'package:json_annotation/json_annotation.dart';

part 'vault_item.g.dart';

/// Model for items saved to the Habit Vault
/// Stores What-If simulations, goal plans, and other saved outputs
@JsonSerializable()
class HabitVaultItem {
  final String id;
  final String title;
  final String? summary;
  final List<VaultSection> sections;
  final List<String>? habits;
  final String? goalType; // 'what-if', 'life-task', 'custom'
  final DateTime savedAt;
  final List<String>? tags;

  HabitVaultItem({
    required this.id,
    required this.title,
    this.summary,
    required this.sections,
    this.habits,
    this.goalType,
    required this.savedAt,
    this.tags,
  });

  factory HabitVaultItem.fromJson(Map<String, dynamic> json) =>
      _$HabitVaultItemFromJson(json);

  Map<String, dynamic> toJson() => _$HabitVaultItemToJson(this);

  /// Create from What-If screen output
  factory HabitVaultItem.fromWhatIfCard({
    required Map<String, dynamic> card,
    List<dynamic>? habits,
  }) {
    final sections = (card['sections'] as List? ?? [])
        .map((s) => VaultSection(
              title: s['title'] ?? '',
              content: s['content'] ?? '',
            ))
        .toList();

    return HabitVaultItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: card['title'] ?? 'What-If Simulation',
      summary: card['summary'],
      sections: sections,
      habits: habits?.map((h) => h.toString()).toList(),
      goalType: 'what-if',
      savedAt: DateTime.now(),
      tags: ['simulation', 'goal'],
    );
  }

  /// Create from simple content
  factory HabitVaultItem.fromContent({
    required String title,
    String? summary,
    required String content,
    String? goalType,
  }) {
    return HabitVaultItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      summary: summary,
      sections: [VaultSection(title: 'Content', content: content)],
      habits: null,
      goalType: goalType ?? 'custom',
      savedAt: DateTime.now(),
      tags: [],
    );
  }

  /// Get full text content for display/export
  String get fullText {
    final buffer = StringBuffer();
    buffer.writeln(title);
    if (summary != null && summary!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(summary);
    }
    buffer.writeln();
    for (var section in sections) {
      if (section.title.isNotEmpty) {
        buffer.writeln('## ${section.title}');
      }
      buffer.writeln(section.content);
      buffer.writeln();
    }
    if (habits != null && habits!.isNotEmpty) {
      buffer.writeln('## Habits');
      for (var habit in habits!) {
        buffer.writeln('• $habit');
      }
    }
    return buffer.toString();
  }
}

@JsonSerializable()
class VaultSection {
  final String title;
  final String content;

  VaultSection({
    required this.title,
    required this.content,
  });

  factory VaultSection.fromJson(Map<String, dynamic> json) =>
      _$VaultSectionFromJson(json);

  Map<String, dynamic> toJson() => _$VaultSectionToJson(this);
}

