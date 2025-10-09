import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/streak.dart';
import 'package:flutter/foundation.dart';

class StreakService {
  static const _key = 'streak_data';

  // Global live notifier for UI to listen to
  final ValueNotifier<StreakData> notifier =
      ValueNotifier<StreakData>(StreakData(currentStreak: 0, longestStreak: 0, totalXP: 0));

  Future<StreakData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      final data = StreakData(currentStreak: 0, longestStreak: 0, totalXP: 0);
      notifier.value = data;
      return data;
    }
    final data = StreakData.fromJson(jsonDecode(raw));
    notifier.value = data;
    return data;
  }

  Future<void> save(StreakData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data.toJson()));
    notifier.value = data;
  }

  Future<void> increment({int xp = 15}) async {
    final data = await load();
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    bool continues = data.lastCompletion != null &&
        _ymd(data.lastCompletion!) == _ymd(yesterday);

    final newStreak = continues ? data.currentStreak + 1 : 1;
    final longest = newStreak > data.longestStreak ? newStreak : data.longestStreak;

    await save(StreakData(
      currentStreak: newStreak,
      longestStreak: longest,
      totalXP: data.totalXP + xp,
      lastCompletion: today,
    ));
  }

  Future<void> checkAndResetStreaks() async {
    final data = await load();
    final today = DateTime.now();
    if (data.lastCompletion == null) return;
    if (today.difference(data.lastCompletion!).inDays >= 2) {
      await save(StreakData(
        currentStreak: 0,
        longestStreak: data.longestStreak,
        totalXP: data.totalXP,
        lastCompletion: data.lastCompletion,
        lastMissed: today,
      ));
    }
  }

  String _ymd(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

final streakService = StreakService();

