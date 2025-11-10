import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chapter_model.dart';

/// CONVERSATION MANAGER
/// 
/// Local-first state management for hour-long conversations:
/// - Auto-save every 5 minutes
/// - Pause/resume capability
/// - Time tracking
/// - Pattern accumulation

class ConversationManager {
  final int chapterNumber;
  
  List<Message> _messages = [];
  DateTime? _sessionStartTime;
  int _totalMinutes = 0;
  Map<String, dynamic> _extractedPatterns = {};
  Timer? _autoSaveTimer;

  ConversationManager({required this.chapterNumber});

  List<Message> get messages => List.unmodifiable(_messages);
  DateTime? get sessionStartTime => _sessionStartTime;
  int get totalMinutes => _totalMinutes;
  Map<String, dynamic> get extractedPatterns => Map.from(_extractedPatterns);
  
  int get exchangeCount => _messages.where((m) => m.role == 'user').length;
  
  Duration get sessionDuration {
    if (_sessionStartTime == null) return Duration.zero;
    return DateTime.now().difference(_sessionStartTime!);
  }

  /// Start new session
  void startSession() {
    _sessionStartTime = DateTime.now();
    _startAutoSave();
  }

  /// Resume existing session
  Future<void> resumeSession() async {
    await _loadFromStorage();
    _sessionStartTime = DateTime.now(); // Fresh session time
    _startAutoSave();
  }

  /// Add user message
  void addUserMessage(String content) {
    _messages.add(Message(
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    ));
    _saveToStorage(); // Immediate save on user input
  }

  /// Add AI message
  void addAssistantMessage(String content) {
    _messages.add(Message(
      role: 'assistant',
      content: content,
      timestamp: DateTime.now(),
    ));
  }

  /// Update extracted patterns from API response
  void updatePatterns(Map<String, dynamic> newPatterns) {
    _extractedPatterns = {
      ..._extractedPatterns,
      ...newPatterns,
    };
  }

  /// Pause session (save state)
  Future<void> pauseSession() async {
    if (_sessionStartTime != null) {
      final elapsed = DateTime.now().difference(_sessionStartTime!).inMinutes;
      _totalMinutes += elapsed;
    }
    
    await _saveToStorage();
    _stopAutoSave();
    _sessionStartTime = null;
  }

  /// Clear session (after successful save to backend)
  Future<void> clearSession() async {
    _messages.clear();
    _sessionStartTime = null;
    _totalMinutes = 0;
    _extractedPatterns.clear();
    _stopAutoSave();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lifetask_chapter_${chapterNumber}_state');
  }

  /// Check if session exists in storage
  Future<bool> hasStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('lifetask_chapter_${chapterNumber}_state');
  }

  /// Auto-save every 5 minutes
  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _saveToStorage(),
    );
  }

  void _stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  /// Save to local storage
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    final state = {
      'messages': _messages.map((m) => m.toJson()).toList(),
      'totalMinutes': _totalMinutes,
      'extractedPatterns': _extractedPatterns,
      'lastSaved': DateTime.now().toIso8601String(),
    };

    await prefs.setString(
      'lifetask_chapter_${chapterNumber}_state',
      jsonEncode(state),
    );
  }

  /// Load from local storage
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final stateJson = prefs.getString('lifetask_chapter_${chapterNumber}_state');
    
    if (stateJson == null) return;

    try {
      final state = jsonDecode(stateJson) as Map<String, dynamic>;
      
      _messages = (state['messages'] as List)
          .map((json) => Message.fromJson(json))
          .toList();
      
      _totalMinutes = state['totalMinutes'] ?? 0;
      _extractedPatterns = state['extractedPatterns'] ?? {};
    } catch (e) {
      print('Error loading session: $e');
      // Continue with empty state
    }
  }

  /// Dispose (cleanup)
  void dispose() {
    _stopAutoSave();
  }
}

