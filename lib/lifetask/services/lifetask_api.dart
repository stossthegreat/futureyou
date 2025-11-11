import 'dart:async';
import '../../services/api_client.dart';
import '../models/chapter_model.dart';

/// LIFE'S TASK API CLIENT
/// 
/// Wraps the existing ApiClient to hit /api/lifetask/* endpoints
/// Uses the same auth, timeouts, and error handling that already works!

class LifeTaskAPI {
  // Use singleton pattern since ApiClient is static
  LifeTaskAPI();

  /// Get full conversation response (uses existing ApiClient)
  Future<ConversationResponse> converse({
    required int chapterNumber,
    required List<Message> messages,
    required DateTime sessionStartTime,
  }) async {
    final response = await ApiClient.lifeTaskConverse(
      chapterNumber: chapterNumber,
      messages: messages.map((m) => m.toJson()).toList(),
      sessionStartTime: sessionStartTime.toIso8601String(),
    );

    if (response.success) {
      return ConversationResponse.fromJson(response.data!);
    } else {
      throw Exception(response.error);
    }
  }

  /// Generate prose chapter (writer mode)
  Future<ChapterProseResponse> generateChapter({
    required int chapterNumber,
    required List<Message> messages,
    required Map<String, dynamic> extractedPatterns,
  }) async {
    final response = await ApiClient.lifeTaskGenerateChapter(
      chapterNumber: chapterNumber,
      conversationTranscript: messages.map((m) => m.toJson()).toList(),
      extractedPatterns: extractedPatterns,
    );

    if (response.success) {
      return ChapterProseResponse.fromJson(response.data!);
    } else {
      throw Exception(response.error);
    }
  }

  /// Save chapter (bulk write at completion)
  Future<void> saveChapter({
    required int chapterNumber,
    required List<Message> messages,
    required String proseText,
    required Map<String, dynamic> extractedPatterns,
    required int timeSpentMinutes,
  }) async {
    final response = await ApiClient.lifeTaskSaveChapter(
      chapterNumber: chapterNumber,
      conversationTranscript: messages.map((m) => m.toJson()).toList(),
      extractedPatterns: extractedPatterns,
      proseText: proseText,
      timeSpentMinutes: timeSpentMinutes,
    );

    if (!response.success) {
      throw Exception(response.error);
    }
  }

  /// Get all chapters
  Future<List<Chapter>> getChapters() async {
    final response = await ApiClient.lifeTaskGetChapters();

    if (response.success) {
      return response.data!.map((json) => Chapter.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception(response.error);
    }
  }

  /// Compile book
  Future<CompiledBook> compileBook() async {
    final response = await ApiClient.lifeTaskCompileBook();

    if (response.success) {
      return CompiledBook.fromJson(response.data!);
    } else {
      throw Exception(response.error);
    }
  }
}

/// Response from conversation endpoint
class ConversationResponse {
  final String coachMessage;
  final bool shouldContinue; // false = chapter can complete
  final DepthMetrics depthMetrics;
  final Map<String, dynamic> extractedPatterns;
  final String? nextPromptHint;

  ConversationResponse({
    required this.coachMessage,
    required this.shouldContinue,
    required this.depthMetrics,
    required this.extractedPatterns,
    this.nextPromptHint,
  });

  factory ConversationResponse.fromJson(Map<String, dynamic> json) {
    return ConversationResponse(
      coachMessage: json['coachMessage'],
      shouldContinue: json['shouldContinue'],
      depthMetrics: DepthMetrics.fromJson(json['depthMetrics']),
      extractedPatterns: json['extractedPatterns'] ?? {},
      nextPromptHint: json['nextPromptHint'],
    );
  }
}

class DepthMetrics {
  final int exchangeCount;
  final int timeElapsedMinutes;
  final int specificScenesCollected;
  final int emotionalMarkersDetected;
  final double vagueResponseRatio;
  final bool minimumExchangesMet;
  final bool minimumTimeMet;
  final bool qualityChecksPassed;

  DepthMetrics({
    required this.exchangeCount,
    required this.timeElapsedMinutes,
    required this.specificScenesCollected,
    required this.emotionalMarkersDetected,
    required this.vagueResponseRatio,
    required this.minimumExchangesMet,
    required this.minimumTimeMet,
    required this.qualityChecksPassed,
  });

  factory DepthMetrics.fromJson(Map<String, dynamic> json) {
    return DepthMetrics(
      exchangeCount: json['exchangeCount'] ?? 0,
      timeElapsedMinutes: json['timeElapsedMinutes'] ?? 0,
      specificScenesCollected: json['specificScenesCollected'] ?? 0,
      emotionalMarkersDetected: json['emotionalMarkersDetected'] ?? 0,
      vagueResponseRatio: (json['vagueResponseRatio'] ?? 0.0) is int 
          ? (json['vagueResponseRatio'] as int).toDouble() 
          : (json['vagueResponseRatio'] as double),
      minimumExchangesMet: json['minimumExchangesMet'] ?? false,
      minimumTimeMet: json['minimumTimeMet'] ?? false,
      qualityChecksPassed: json['qualityChecksPassed'] ?? false,
    );
  }
}

/// Response from chapter generation endpoint
class ChapterProseResponse {
  final String proseText;
  final int wordCount;

  ChapterProseResponse({
    required this.proseText,
    required this.wordCount,
  });

  factory ChapterProseResponse.fromJson(Map<String, dynamic> json) {
    return ChapterProseResponse(
      proseText: json['proseText'],
      wordCount: json['wordCount'],
    );
  }
}

/// Compiled book
class CompiledBook {
  final String title;
  final String markdown;
  final List<String> chapterIds;
  final DateTime createdAt;

  CompiledBook({
    required this.title,
    required this.markdown,
    required this.chapterIds,
    required this.createdAt,
  });

  factory CompiledBook.fromJson(Map<String, dynamic> json) {
    return CompiledBook(
      title: json['title'],
      markdown: json['markdown'],
      chapterIds: List<String>.from(json['chapterIds']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
