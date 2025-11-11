// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vault_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HabitVaultItem _$HabitVaultItemFromJson(Map<String, dynamic> json) =>
    HabitVaultItem(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String?,
      sections: (json['sections'] as List<dynamic>)
          .map((e) => VaultSection.fromJson(e as Map<String, dynamic>))
          .toList(),
      habits: (json['habits'] as List<dynamic>?)?.map((e) => e as String).toList(),
      goalType: json['goalType'] as String?,
      savedAt: DateTime.parse(json['savedAt'] as String),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$HabitVaultItemToJson(HabitVaultItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'summary': instance.summary,
      'sections': instance.sections.map((e) => e.toJson()).toList(),
      'habits': instance.habits,
      'goalType': instance.goalType,
      'savedAt': instance.savedAt.toIso8601String(),
      'tags': instance.tags,
    };

VaultSection _$VaultSectionFromJson(Map<String, dynamic> json) =>
    VaultSection(
      title: json['title'] as String,
      content: json['content'] as String,
    );

Map<String, dynamic> _$VaultSectionToJson(VaultSection instance) =>
    <String, dynamic>{
      'title': instance.title,
      'content': instance.content,
    };

