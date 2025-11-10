/// Chapter model for Life's Task Discovery Engine

class Chapter {
  final int number;
  final String title;
  final String subtitle;
  final ChapterStatus status;
  final List<Message> messages;
  final int timeSpentMinutes;
  final DateTime? completedAt;
  final String? generatedProseText;
  final Map<String, dynamic>? extractedPatterns;

  Chapter({
    required this.number,
    required this.title,
    required this.subtitle,
    this.status = ChapterStatus.locked,
    this.messages = const [],
    this.timeSpentMinutes = 0,
    this.completedAt,
    this.generatedProseText,
    this.extractedPatterns,
  });

  Chapter copyWith({
    ChapterStatus? status,
    List<Message>? messages,
    int? timeSpentMinutes,
    DateTime? completedAt,
    String? generatedProseText,
    Map<String, dynamic>? extractedPatterns,
  }) {
    return Chapter(
      number: number,
      title: title,
      subtitle: subtitle,
      status: status ?? this.status,
      messages: messages ?? this.messages,
      timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
      completedAt: completedAt ?? this.completedAt,
      generatedProseText: generatedProseText ?? this.generatedProseText,
      extractedPatterns: extractedPatterns ?? this.extractedPatterns,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'title': title,
      'subtitle': subtitle,
      'status': status.toString(),
      'messages': messages.map((m) => m.toJson()).toList(),
      'timeSpentMinutes': timeSpentMinutes,
      'completedAt': completedAt?.toIso8601String(),
      'generatedProseText': generatedProseText,
      'extractedPatterns': extractedPatterns,
    };
  }

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      number: json['number'],
      title: json['title'],
      subtitle: json['subtitle'],
      status: ChapterStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => ChapterStatus.locked,
      ),
      messages: (json['messages'] as List?)
              ?.map((m) => Message.fromJson(m))
              .toList() ??
          [],
      timeSpentMinutes: json['timeSpentMinutes'] ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      generatedProseText: json['generatedProseText'],
      extractedPatterns: json['extractedPatterns'],
    );
  }
}

enum ChapterStatus {
  locked,
  available,
  inProgress,
  completed,
}

class Message {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  Message({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: json['role'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Get all 7 chapters with initial state
List<Chapter> getInitialChapters() {
  return [
    Chapter(
      number: 1,
      title: 'Chapter I',
      subtitle: 'The Call',
      status: ChapterStatus.available,
    ),
    Chapter(
      number: 2,
      title: 'Chapter II',
      subtitle: 'The Conflict',
      status: ChapterStatus.locked,
    ),
    Chapter(
      number: 3,
      title: 'Chapter III',
      subtitle: 'The Mirror',
      status: ChapterStatus.locked,
    ),
    Chapter(
      number: 4,
      title: 'Chapter IV',
      subtitle: 'The Mentor',
      status: ChapterStatus.locked,
    ),
    Chapter(
      number: 5,
      title: 'Chapter V',
      subtitle: 'The Task',
      status: ChapterStatus.locked,
    ),
    Chapter(
      number: 6,
      title: 'Chapter VI',
      subtitle: 'The Path',
      status: ChapterStatus.locked,
    ),
    Chapter(
      number: 7,
      title: 'Chapter VII',
      subtitle: 'The Promise',
      status: ChapterStatus.locked,
    ),
  ];
}

