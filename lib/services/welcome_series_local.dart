import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/coach_message.dart' as model;
import '../data/welcome_series_content.dart';

/// Local service to track and manage welcome series progress
class WelcomeSeriesLocal {
  static const String _boxName = 'welcome_series';
  late Box<dynamic> _box;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox(_boxName);
    _initialized = true;
    debugPrint('✅ Welcome Series Local initialized');
  }

  /// Check if welcome series has been started
  bool hasStarted() {
    if (!_initialized) return false;
    return _box.get('started', defaultValue: false) as bool;
  }

  /// Start the welcome series
  Future<void> start() async {
    if (!_initialized) await init();
    await _box.put('started', true);
    await _box.put('start_date', DateTime.now().toIso8601String());
    await _box.put('current_day', 1);
    debugPrint('🌑 Welcome Series started');
  }

  /// Get current day (1-7)
  int getCurrentDay() {
    if (!_initialized || !hasStarted()) return 1;
    return _box.get('current_day', defaultValue: 1) as int;
  }

  /// Check if series is complete
  bool isComplete() {
    if (!_initialized || !hasStarted()) return false;
    return getCurrentDay() > 7;
  }

  /// Check if today's day has been read
  bool hasTodayBeenRead() {
    if (!_initialized || !hasStarted()) return false;
    
    final currentDay = getCurrentDay();
    if (currentDay > 7) return true;
    
    final lastReadDate = _box.get('day_${currentDay}_read_date');
    if (lastReadDate == null) return false;
    
    final lastRead = DateTime.parse(lastReadDate as String);
    final now = DateTime.now();
    
    // Check if read today
    return lastRead.year == now.year &&
           lastRead.month == now.month &&
           lastRead.day == now.day;
  }

  /// Mark current day as read and advance to next day
  Future<void> markDayComplete() async {
    if (!_initialized) await init();
    
    final currentDay = getCurrentDay();
    if (currentDay > 7) return;
    
    // Mark current day as read
    await _box.put('day_${currentDay}_read_date', DateTime.now().toIso8601String());
    
    // Advance to next day
    final nextDay = currentDay + 1;
    await _box.put('current_day', nextDay);
    
    if (nextDay > 7) {
      await _box.put('completed', true);
      await _box.put('completed_date', DateTime.now().toIso8601String());
      debugPrint('✨ Welcome Series completed!');
    } else {
      debugPrint('✅ Day $currentDay complete. Next: Day $nextDay');
    }
  }

  /// Check if we should show today's welcome day
  /// Only shows if:
  /// 1. Series has started
  /// 2. Not yet complete (day <= 7)
  /// 3. Current day hasn't been read today
  bool shouldShowToday() {
    if (!hasStarted()) return false;
    if (isComplete()) return false;
    if (hasTodayBeenRead()) return false;
    return true;
  }

  /// Get the content for today's day
  WelcomeDayContent? getTodaysContent() {
    if (!shouldShowToday()) return null;
    final day = getCurrentDay();
    return getWelcomeDay(day);
  }

  /// Convert welcome day to CoachMessage for storage in reflections
  model.CoachMessage welcomeDayToMessage(WelcomeDayContent dayContent) {
    return model.CoachMessage(
      id: 'welcome_day_${dayContent.day}',
      kind: model.MessageKind.letter,
      content: '${dayContent.moonPhase} ${dayContent.title}\n\n${dayContent.content}',
      timestamp: DateTime.now(),
      isRead: false,
      metadata: {
        'source': 'welcome_series',
        'day': dayContent.day,
        'moonPhase': dayContent.moonPhase,
        'title': dayContent.title,
      },
    );
  }

  /// Reset series (for testing)
  Future<void> reset() async {
    if (!_initialized) await init();
    await _box.clear();
    debugPrint('🔄 Welcome Series reset');
  }

  /// Get stats for debugging
  Map<String, dynamic> getStats() {
    if (!_initialized) return {};
    
    return {
      'started': hasStarted(),
      'current_day': getCurrentDay(),
      'is_complete': isComplete(),
      'should_show_today': shouldShowToday(),
      'today_read': hasTodayBeenRead(),
    };
  }
}

// Singleton instance
final welcomeSeriesLocal = WelcomeSeriesLocal();

