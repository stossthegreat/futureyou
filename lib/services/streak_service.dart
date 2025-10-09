import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/streak.dart';
import '../services/local_storage.dart';

/// Global provider to access streak state and actions reactively
final streakServiceProvider =
    StateNotifierProvider<StreakServiceNotifier, StreakData>((ref) {
  return StreakServiceNotifier();
});

class StreakServiceNotifier extends StateNotifier<StreakData> {
  static const _key = 'streak_data';

  StreakServiceNotifier()
      : super(StreakData(
          currentStreak: 0,
          longestStreak: 0,
          totalXP: 0,
          lastCompletion: null,
        )) {
    _load();
  }

  // ---------------- LOAD / SAVE ----------------

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      await _save(state);
      return;
    }
    final data = StreakData.fromJson(jsonDecode(raw));
    state = data;
  }

  Future<void> _save(StreakData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data.toJson()));
    state = data;
  }

  // ---------------- INCREMENT ----------------

  /// Called when user completes a habit for today
  Future<void> increment({int xp = 15}) async {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    final lastCompletion = state.lastCompletion;
    final continues =
        lastCompletion != null && _isSameDay(lastCompletion, yesterday);

    final newStreak = continues ? state.currentStreak + 1 : 1;
    final longest =
        newStreak > state.longestStreak ? newStreak : state.longestStreak;

    final updated = state.copyWith(
      currentStreak: newStreak,
      longestStreak: longest,
      totalXP: state.totalXP + xp,
      lastCompletion: today,
    );
    await _save(updated);
  }

  // ---------------- RESET / CHECK ----------------

  /// Called each morning (5am job) to reset streaks if missed 2+ days
  Future<void> checkAndResetStreaks() async {
    final today = DateTime.now();
    if (state.lastCompletion == null) return;
    final diff = today.difference(state.lastCompletion!).inDays;
    if (diff >= 2) {
      final reset = state.copyWith(
        currentStreak: 0,
        lastMissed: today,
      );
      await _save(reset);
    }
  }

  /// Force recompute from actual habit data (for full accuracy)
  Future<void> refreshStreaks() async {
    final current = LocalStorageService.calculateCurrentStreak();
    final longest = LocalStorageService.calculateLongestStreak();
    final updated = state.copyWith(
      currentStreak: current,
      longestStreak: longest,
    );
    await _save(updated);
  }

  // ---------------- UTIL ----------------

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
