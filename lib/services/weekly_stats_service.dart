import '../services/local_storage.dart';

class WeeklyStats {
  final int perfectDays;
  final int microWins;
  final int driftDays;
  final double trendingPercentage;

  WeeklyStats({
    required this.perfectDays,
    required this.microWins,
    required this.driftDays,
    required this.trendingPercentage,
  });
}

class WeeklyStatsService {
  /// Calculate stats for the current calendar week (Monday-Sunday)
  static WeeklyStats calculateCurrentWeekStats() {
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);

    int perfectDays = 0;
    int microWins = 0;
    int driftDays = 0;

    final habits = LocalStorageService.getAllHabits();
    if (habits.isEmpty) {
      return WeeklyStats(
        perfectDays: 0,
        microWins: 0,
        driftDays: 0,
        trendingPercentage: 0.0,
      );
    }

    // Iterate through each day of the week
    for (int i = 0; i < 7; i++) {
      final checkDate = weekStart.add(Duration(days: i));
      
      // Skip future dates
      if (checkDate.isAfter(now)) continue;

      final fulfillmentPercent = LocalStorageService.getFulfillmentPercentage(checkDate);
      
      // Check if there were any habits scheduled for this day
      final scheduledHabits = habits.where((h) => h.isScheduledForDate(checkDate)).toList();
      if (scheduledHabits.isEmpty) {
        // No habits scheduled = drift day
        driftDays++;
      } else if (fulfillmentPercent == 100.0) {
        perfectDays++;
      } else if (fulfillmentPercent > 0 && fulfillmentPercent < 100.0) {
        microWins++;
      } else {
        // 0% completion
        driftDays++;
      }
    }

    // Calculate trending percentage (simple completion rate for the week)
    final totalDays = perfectDays + microWins + driftDays;
    final trendingPercentage = totalDays > 0 
        ? ((perfectDays + microWins) / totalDays * 100)
        : 0.0;

    return WeeklyStats(
      perfectDays: perfectDays,
      microWins: microWins,
      driftDays: driftDays,
      trendingPercentage: trendingPercentage,
    );
  }

  /// Get the start of the current week (Monday)
  static DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // Monday = 1, Sunday = 7
    final diff = weekday - 1; // Days since Monday
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: diff));
  }
}

