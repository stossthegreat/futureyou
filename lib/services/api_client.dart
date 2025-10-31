import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/habit.dart';

class ApiClient {
  // Future-You OS Backend Integration
  static const String _baseUrl = 'https://futureyou-production.up.railway.app'; // Railway URL
  static const String _localUrl = 'http://localhost:8080'; // For local development
  static const Duration _timeout = Duration(seconds: 30);
  
  // Generate persistent user ID on first launch
  // TODO: Replace with real auth system later
  static String _userId = 'test-user-felix'; // Fixed for testing, change after auth is added
  
  static final Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'x-user-id': _userId, // Backend uses this header for user identification
  };
  
  // Set custom user ID (for testing or if user signs in)
  static void setUserId(String userId) {
    _userId = userId;
    _defaultHeaders['x-user-id'] = userId;
    debugPrint('✓ User ID set to: $userId');
  }
  
  static String get userId => _userId;
  
  // Authentication token (to be set after login)
  static String? _authToken;
  
  static void setAuthToken(String token) {
    _authToken = token;
  }
  
  static Map<String, String> get _headers {
    final headers = Map<String, String>.from(_defaultHeaders);
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }
  
  // Generic HTTP methods
  static Future<http.Response> _get(String endpoint) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http.get(uri, headers: _headers).timeout(_timeout);
      return response;
    } catch (e) {
      debugPrint('GET request failed: $e');
      rethrow;
    }
  }
  
  static Future<http.Response> _post(String endpoint, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(_timeout);
      return response;
    } catch (e) {
      debugPrint('POST request failed: $e');
      rethrow;
    }
  }
  
  static Future<http.Response> _put(String endpoint, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http.put(
        uri,
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(_timeout);
      return response;
    } catch (e) {
      debugPrint('PUT request failed: $e');
      rethrow;
    }
  }
  
  static Future<http.Response> _delete(String endpoint) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http.delete(uri, headers: _headers).timeout(_timeout);
      return response;
    } catch (e) {
      debugPrint('DELETE request failed: $e');
      rethrow;
    }
  }
  
  // Habit API endpoints
  static Future<ApiResponse<Habit>> createHabit(Habit habit) async {
    try {
      final response = await _post('/habits', habit.toJson());
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(Habit.fromJson(data));
      } else {
        return ApiResponse.error('Failed to create habit: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }
  
  static Future<ApiResponse<Habit>> updateHabit(Habit habit) async {
    try {
      final response = await _put('/habits/${habit.id}', habit.toJson());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(Habit.fromJson(data));
      } else {
        return ApiResponse.error('Failed to update habit: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }
  
  static Future<ApiResponse<void>> deleteHabit(String habitId) async {
    try {
      final response = await _delete('/habits/$habitId');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse.success(null);
      } else {
        return ApiResponse.error('Failed to delete habit: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }
  
  static Future<ApiResponse<List<Habit>>> getHabits() async {
    try {
      final response = await _get('/habits');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final habits = data.map((json) => Habit.fromJson(json)).toList();
        return ApiResponse.success(habits);
      } else {
        return ApiResponse.error('Failed to fetch habits: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }
  
  static Future<ApiResponse<void>> logAction(String habitId, bool completed, DateTime timestamp) async {
    try {
      final data = {
        'habitId': habitId,
        'completed': completed,
        'timestamp': timestamp.toIso8601String(),
      };
      
      final response = await _post('/habits/log', data);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(null);
      } else {
        return ApiResponse.error('Failed to log action: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }
  
  // Chat API endpoints
  static Future<ApiResponse<ChatResponse>> sendChatMessage(String message) async {
    try {
      final data = {
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final response = await _post('/chat/send', data);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return ApiResponse.success(ChatResponse.fromJson(responseData));
      } else {
        return ApiResponse.error('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }
  
  static Future<ApiResponse<List<ChatMessage>>> getChatHistory() async {
    try {
      final response = await _get('/chat/history');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final messages = data.map((json) => ChatMessage.fromJson(json)).toList();
        return ApiResponse.success(messages);
      } else {
        return ApiResponse.error('Failed to fetch chat history: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }
  
  // Sync API endpoints
  static Future<ApiResponse<SyncResponse>> syncAll(List<Habit> localHabits) async {
    try {
      final data = {
        'habits': localHabits.map((h) => h.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final response = await _post('/sync/all', data);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return ApiResponse.success(SyncResponse.fromJson(responseData));
      } else {
        return ApiResponse.error('Failed to sync: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }
  
  // Analytics API endpoints
  static Future<ApiResponse<AnalyticsData>> getAnalytics(DateTime startDate, DateTime endDate) async {
    try {
      final queryParams = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };
      
      final uri = Uri.parse('$_baseUrl/analytics').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(AnalyticsData.fromJson(data));
      } else {
        return ApiResponse.error('Failed to fetch analytics: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Coach API endpoints - Future-You OS Brain Layer
  static Future<ApiResponse<void>> syncCoachData(List<Habit> habits, List<HabitCompletion> completions) async {
    try {
      final data = {
        'habits': habits.map((h) => h.toJson()).toList(),
        'completions': completions.map((c) => c.toJson()).toList(),
      };
      
      final response = await _post('/api/v1/coach/sync', data);
      
      if (response.statusCode == 200) {
        return ApiResponse.success(null);
      } else {
        return ApiResponse.error('Failed to sync coach data: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  static Future<ApiResponse<List<CoachMessage>>> getCoachMessages() async {
    try {
      final response = await _get('/api/v1/coach/messages');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = (data['messages'] as List)
            .map((json) => CoachMessage.fromJson(json))
            .toList();
        return ApiResponse.success(messages);
      } else {
        return ApiResponse.error('Failed to fetch coach messages: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Helper method to update base URL after Railway deployment
  static void updateBaseUrl(String newBaseUrl) {
    // This would require making _baseUrl non-final and adding a setter
    // For now, users should update the _baseUrl constant directly
    debugPrint('Update _baseUrl constant to: $newBaseUrl');
  }

  // AI chat with optional voice (backend: POST /v1/chat)
  static Future<ApiResponse<AiChatResult>> chatWithVoice(String message, { String mode = 'balanced', bool includeVoice = true }) async {
    try {
      final body = {
        'message': message,
        'mode': mode,
        'includeVoice': includeVoice,
      };
      final resp = await _post('/v1/chat', body);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final reply = (data['reply'] ?? '').toString();
        final voiceUrl = (data['voice'] != null && data['voice']['url'] != null) ? data['voice']['url'] as String : null;
        return ApiResponse.success(AiChatResult(reply: reply, voiceUrl: voiceUrl));
      } else {
        return ApiResponse.error('Chat failed: ${resp.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Messages API - Get all coach messages (briefs, nudges, debriefs)
  static Future<http.Response> getMessages(String userId) async {
    return await _get('/api/v1/coach/messages');
  }

  // Mark message as read
  static Future<http.Response> markMessageAsRead(String messageId) async {
    return await _post('/api/v1/coach/messages/$messageId/read', {});
  }

  // Chat with Future You (enhanced endpoint) - Returns properly parsed response
  static Future<ApiResponse<Map<String, dynamic>>> sendChatMessageV2(String message) async {
    try {
      final response = await _post('/api/v1/chat', {'message': message});
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(data);
      } else {
        return ApiResponse.error('Chat failed: ${response.statusCode}');
      }
    } on TimeoutException {
      return ApiResponse.error('Request timed out. Please try again.');
    } on SocketException {
      return ApiResponse.error('No internet connection.');
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }
}

// Response wrapper class
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  
  ApiResponse.success(this.data) : success = true, error = null;
  ApiResponse.error(this.error) : success = false, data = null;
}

// Chat related models
class ChatMessage {
  final String id;
  final String role; // 'user' or 'future'
  final String text;
  final DateTime timestamp;
  
  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
  });
  
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      role: json['role'],
      text: json['text'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ChatResponse {
  final String message;
  final List<QuickCommit>? quickCommits;
  
  ChatResponse({
    required this.message,
    this.quickCommits,
  });
  
  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      message: json['message'],
      quickCommits: json['quickCommits'] != null
          ? (json['quickCommits'] as List)
              .map((q) => QuickCommit.fromJson(q))
              .toList()
          : null,
    );
  }
}

class QuickCommit {
  final String label;
  final String type;
  final String title;
  final String time;
  
  QuickCommit({
    required this.label,
    required this.type,
    required this.title,
    required this.time,
  });
  
  factory QuickCommit.fromJson(Map<String, dynamic> json) {
    return QuickCommit(
      label: json['label'],
      type: json['type'],
      title: json['title'],
      time: json['time'],
    );
  }
}

// Sync related models
class SyncResponse {
  final List<Habit> updatedHabits;
  final List<String> deletedHabitIds;
  final DateTime lastSyncTime;
  
  SyncResponse({
    required this.updatedHabits,
    required this.deletedHabitIds,
    required this.lastSyncTime,
  });
  
  factory SyncResponse.fromJson(Map<String, dynamic> json) {
    return SyncResponse(
      updatedHabits: (json['updatedHabits'] as List)
          .map((h) => Habit.fromJson(h))
          .toList(),
      deletedHabitIds: List<String>.from(json['deletedHabitIds']),
      lastSyncTime: DateTime.parse(json['lastSyncTime']),
    );
  }
}

// Analytics related models
class AnalyticsData {
  final double averageFulfillment;
  final int totalHabits;
  final int completedHabits;
  final int currentStreak;
  final int longestStreak;
  final Map<String, double> weeklyTrends;
  
  AnalyticsData({
    required this.averageFulfillment,
    required this.totalHabits,
    required this.completedHabits,
    required this.currentStreak,
    required this.longestStreak,
    required this.weeklyTrends,
  });
  
  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      averageFulfillment: json['averageFulfillment'].toDouble(),
      totalHabits: json['totalHabits'],
      completedHabits: json['completedHabits'],
      currentStreak: json['currentStreak'],
      longestStreak: json['longestStreak'],
      weeklyTrends: Map<String, double>.from(json['weeklyTrends']),
    );
  }
}

// AI chat response with optional voice
class AiChatResult {
  final String reply;
  final String? voiceUrl;
  AiChatResult({ required this.reply, this.voiceUrl });
}

// Coach related models - Future-You OS Brain Layer
class HabitCompletion {
  final String habitId;
  final DateTime date;
  final bool done;
  final DateTime? completedAt;
  
  HabitCompletion({
    required this.habitId,
    required this.date,
    required this.done,
    this.completedAt,
  });
  
  factory HabitCompletion.fromJson(Map<String, dynamic> json) {
    return HabitCompletion(
      habitId: json['habitId'],
      date: DateTime.parse(json['date']),
      done: json['done'],
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'habitId': habitId,
      'date': date.toIso8601String(),
      'done': done,
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}

enum CoachMessageKind { nudge, brief, mirror, letter }

class CoachMessage {
  final String id;
  final String userId;
  final CoachMessageKind kind;
  final String title;
  final String body;
  final Map<String, dynamic>? meta;
  final DateTime createdAt;
  final DateTime? readAt;
  
  CoachMessage({
    required this.id,
    required this.userId,
    required this.kind,
    required this.title,
    required this.body,
    this.meta,
    required this.createdAt,
    this.readAt,
  });
  
  factory CoachMessage.fromJson(Map<String, dynamic> json) {
    return CoachMessage(
      id: json['id'],
      userId: json['userId'],
      kind: CoachMessageKind.values.firstWhere(
        (e) => e.name == json['kind'],
        orElse: () => CoachMessageKind.nudge,
      ),
      title: json['title'],
      body: json['body'],
      meta: json['meta'],
      createdAt: DateTime.parse(json['createdAt']),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'kind': kind.name,
      'title': title,
      'body': body,
      'meta': meta,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }
}
