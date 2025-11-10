import 'dart:async';
import 'dart:convert';
import '../../services/api_client.dart'; // Use existing working API client!
import '../models/chapter_model.dart';

/// LIFE'S TASK API CLIENT
/// 
/// Wraps the existing ApiClient to hit /api/lifetask/* endpoints
/// Uses the same auth, timeouts, and error handling that already works!

class LifeTaskAPI {
  // Use singleton pattern since ApiClient is static
  LifeTaskAPI();

  /// Stream AI conversation responses (excavation mode)
  /// Returns stream of partial responses for real-time typing effect
  Stream<String> converseStream({
    required int chapterNumber,
    required List<Message> messages,
    required DateTime sessionStartTime,
  }) async* {
    final uri = Uri.parse('$baseUrl/api/lifetask/conversation');
    final token = getAuthToken();

    final request = http.Request('POST', uri)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      })
      ..body = jsonEncode({
        'chapterNumber': chapterNumber,
        'messages': messages.map((m) => m.toJson()).toList(),
        'sessionStartTime': sessionStartTime.toIso8601String(),
      });

    final streamedResponse = await request.send();

    if (streamedResponse.statusCode != 200) {
      throw Exception('API error: ${streamedResponse.statusCode}');
    }

    // Parse SSE (Server-Sent Events) or line-delimited JSON
    await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
      // Each chunk is a partial response
      yield chunk;
    }
  }

  /// Get full conversation response (uses existing ApiClient)
  Future<ConversationResponse> converse({
    required int chapterNumber,
    required List<Message> messages,
    required DateTime sessionStartTime,
  }) async {
    try {
      // Use the existing ApiClient that already works!
      final response = await ApiClient.post(
        '/api/lifetask/conversation',
        {
          'chapterNumber': chapterNumber,
          'messages': messages.map((m) => m.toJson()).toList(),
          'sessionStartTime': sessionStartTime.toIso8601String(),
        },
      );

      if (response.statusCode != 200) {
        throw Exception('API error: ${response.statusCode} - ${response.body}');
      }

      final data = jsonDecode(response.body);
      return ConversationResponse.fromJson(data);
    } catch (e) {
      print('❌ Life Task API Error: $e');
      rethrow;
    }
  }

  /// Generate prose chapter (writer mode)
  Future<ChapterProseResponse> generateChapter({
    required int chapterNumber,
    required List<Message> messages,
    required Map<String, dynamic> extractedPatterns,
  }) async {
    final response = await ApiClient.post(
      '/api/lifetask/chapters/generate',
      {
        'chapterNumber': chapterNumber,
        'conversationTranscript': messages.map((m) => m.toJson()).toList(),
        'extractedPatterns': extractedPatterns,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    return ChapterProseResponse.fromJson(data);
  }

  /// Save chapter (bulk write at completion)
  Future<void> saveChapter({
    required int chapterNumber,
    required List<Message> messages,
    required String proseText,
    required Map<String, dynamic> extractedPatterns,
    required int timeSpentMinutes,
  }) async {
    final response = await ApiClient.post(
      '/api/lifetask/chapters/save',
      {
        'chapterNumber': chapterNumber,
        'conversationTranscript': messages.map((m) => m.toJson()).toList(),
        'extractedPatterns': extractedPatterns,
        'proseText': proseText,
        'timeSpentMinutes': timeSpentMinutes,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save chapter');
    }
  }

  /// Get all chapters
  Future<List<Chapter>> getChapters() async {
    final response = await ApiClient.get('/api/lifetask/chapters');

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch chapters');
    }

    final data = jsonDecode(response.body) as List;
    return data.map((json) => Chapter.fromJson(json)).toList();
  }

  /// Compile book
  Future<CompiledBook> compileBook() async {
    final response = await ApiClient.post('/api/lifetask/book/compile', {});

    if (response.statusCode != 200) {
      throw Exception('Failed to compile book');
    }

    final data = jsonDecode(response.body);
    return CompiledBook.fromJson(data);
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
  final int timeElapsed;
  final double specificityScore;
  final double authenticityScore;
  final double emotionalDepth;
  final bool canComplete;
  final List<String> missingElements;

  DepthMetrics({
    required this.exchangeCount,
    required this.timeElapsed,
    required this.specificityScore,
    required this.authenticityScore,
    required this.emotionalDepth,
    required this.canComplete,
    required this.missingElements,
  });

  factory DepthMetrics.fromJson(Map<String, dynamic> json) {
    return DepthMetrics(
      exchangeCount: json['exchangeCount'],
      timeElapsed: json['timeElapsed'],
      specificityScore: (json['specificityScore'] as num).toDouble(),
      authenticityScore: (json['authenticityScore'] as num).toDouble(),
      emotionalDepth: (json['emotionalDepth'] as num).toDouble(),
      canComplete: json['canComplete'],
      missingElements: List<String>.from(json['missingElements'] ?? []),
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

