import 'package:hive/hive.dart';

part 'coach_message.g.dart';

enum MessageKind {
  nudge,
  brief,
  debrief,
  mirror,
  letter,
  chat,
}

@HiveType(typeId: 3)
class CoachMessage extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final MessageKind kind;

  @HiveField(3)
  final String title;

  @HiveField(4)
  final String body;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  bool isRead;

  @HiveField(7)
  final Map<String, dynamic>? meta;

  CoachMessage({
    required this.id,
    required this.userId,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.meta,
  });

  factory CoachMessage.fromJson(Map<String, dynamic> json) {
    return CoachMessage(
      id: json['id'] as String,
      userId: json['userId'] as String,
      kind: _parseKind(json['kind'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['readAt'] != null,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'kind': kind.name,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'meta': meta,
    };
  }

  static MessageKind _parseKind(String kind) {
    switch (kind.toLowerCase()) {
      case 'nudge':
        return MessageKind.nudge;
      case 'brief':
        return MessageKind.brief;
      case 'debrief':
        return MessageKind.debrief;
      case 'mirror':
        return MessageKind.mirror;
      case 'letter':
        return MessageKind.letter;
      case 'chat':
        return MessageKind.chat;
      default:
        return MessageKind.chat;
    }
  }

  String get emoji {
    switch (kind) {
      case MessageKind.brief:
        return '🌅';
      case MessageKind.nudge:
        return '🔴';
      case MessageKind.debrief:
        return '🌙';
      case MessageKind.letter:
        return '💌';
      case MessageKind.mirror:
        return '🪞';
      case MessageKind.chat:
        return '💬';
    }
  }

  String get kindLabel {
    switch (kind) {
      case MessageKind.brief:
        return 'Morning Brief';
      case MessageKind.nudge:
        return 'Nudge';
      case MessageKind.debrief:
        return 'Evening Debrief';
      case MessageKind.letter:
        return 'Letter from Future You';
      case MessageKind.mirror:
        return 'Mirror Reflection';
      case MessageKind.chat:
        return 'Chat';
    }
  }
}

