import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/habit.dart';

class ApiClient {
  // Future-You OS Backend Integration
  static const String _baseUrl = 'https://futureyou-production.up.railway.app'; // Railway URL
  static const String _localUrl = 'http://localhost:8080'; // For local development
  static const Duration _timeout = Duration(seconds: 30);
  
  // Use demo user for now
  static const String _demoUserId = 'demo-user-123';
  
  static final Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'x-user-id': _demoUserId,
  };

  // ✅ public getters (for HomeScreen use)
  static String get baseUrl => _baseUrl;
  static Map<String, String> get defaultHeaders => _defaultHeaders;
  
  // Authentication token
  static String? _authToken;
  static void setAuthToken(String token) => _authToken = token;
  
  static Map<String, String> get _headers {
    final headers = Map<String, String>.from(_defaultHeaders);
    if (_authToken != null) headers['Authorization'] = 'Bearer $_authToken';
    return headers;
  }

  // ========== Generic HTTP ==========
  static Future<http.Response> _get(String endpoint) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      return await http.get(uri, headers: _headers).timeout(_timeout);
    } catch (e) {
      debugPrint('GET failed: $e');
      rethrow;
    }
  }

  static Future<http.Response> _post(String endpoint, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      return await http.post(uri, headers: _headers, body: jsonEncode(data)).timeout(_timeout);
    } catch (e) {
      debugPrint('POST failed: $e');
      rethrow;
    }
  }

  static Future<http.Response> _put(String endpoint, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      return await http.put(uri, headers: _headers, body: jsonEncode(data)).timeout(_timeout);
    } catch (e) {
      debugPrint('PUT failed: $e');
      rethrow;
    }
  }

  static Future<http.Response> _delete(String endpoint) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      return await http.delete(uri, headers: _headers).timeout(_timeout);
    } catch (e) {
      debugPrint('DELETE failed: $e');
      rethrow;
    }
  }

  // ========== Habit API ==========
  static Future<ApiResponse<Habit>> createHabit(Habit habit) async {
    try {
      final res = await _post('/habits', habit.toJson());
      if (res.statusCode == 201) {
        return ApiResponse.success(Habit.fromJson(jsonDecode(res.body)));
      } else {
        return ApiResponse.error('Failed to create habit: ${res.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  static Future<ApiResponse<Habit>> updateHabit(Habit habit) async {
    try {
      final res = await _put('/habits/${habit.id}', habit.toJson());
      if (res.statusCode == 200) {
        return ApiResponse.success(Habit.fromJson(jsonDecode(res.body)));
      } else {
        return ApiResponse.error('Failed to update habit: ${res.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  static Future<ApiResponse<void>> deleteHabit(String habitId) async {
    try {
      final res = await _delete('/habits/$habitId');
      return (res.statusCode == 200 || res.statusCode == 204)
          ? ApiResponse.success(null)
          : ApiResponse.error('Failed to delete habit: ${res.statusCode}');
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  static Future<ApiResponse<List<Habit>>> getHabits() async {
    try {
      final res = await _get('/habits');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        return ApiResponse.success(data.map((e) => Habit.fromJson(e)).toList());
      } else {
        return ApiResponse.error('Failed to fetch habits: ${res.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // ========== Coach API ==========
  static Future<ApiResponse<void>> syncCoachData(List<Habit> habits, List<HabitCompletion> completions) async {
    try {
      final data = {
        'habits': habits.map((h) => h.toJson()).toList(),
        'completions': completions.map((c) => c.toJson()).toList(),
      };
      final res = await _post('/api/v1/coach/sync', data);
      return (res.statusCode == 200)
          ? ApiResponse.success(null)
          : ApiResponse.error('Failed to sync coach data: ${res.statusCode}');
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  static Future<ApiResponse<List<CoachMessage>>> getCoachMessages() async {
    try {
      final res = await _get('/api/v1/coach/messages');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final msgs = (data['messages'] as List).map((e) => CoachMessage.fromJson(e)).toList();
        return ApiResponse.success(msgs);
      } else {
        return ApiResponse.error('Failed to fetch coach messages: ${res.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // ✅ Add missing generateLetter method
  static Future<ApiResponse<String>> generateLetter(String topic) async {
    try {
      final res = await _post('/api/v1/coach/reflect', { 'topic': topic });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return ApiResponse.success(data['message'] ?? '');
      } else {
        return ApiResponse.error('Failed to generate letter: ${res.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // ========== Helpers ==========
  static void updateBaseUrl(String newBaseUrl) {
    debugPrint('Update _baseUrl constant to: $newBaseUrl');
  }
}

// ========== Response Models ==========
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  ApiResponse.success(this.data) : success = true, error = null;
  ApiResponse.error(this.error) : success = false, data = null;
}

class HabitCompletion {
  final String habitId;
  final DateTime date;
  final bool done;
  final DateTime? completedAt;
  HabitCompletion({ required this.habitId, required this.date, required this.done, this.completedAt });
  Map<String, dynamic> toJson() => {
    'habitId': habitId,
    'date': date.toIso8601String(),
    'done': done,
    'completedAt': completedAt?.toIso8601String(),
  };
  factory HabitCompletion.fromJson(Map<String, dynamic> json) => HabitCompletion(
    habitId: json['habitId'],
    date: DateTime.parse(json['date']),
    done: json['done'],
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
  );
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
      meta: json['meta'] != null ? Map<String, dynamic>.from(json['meta']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
    );
  }
}
