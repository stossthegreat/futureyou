class StreakData {
  int currentStreak;
  int longestStreak;
  int totalXP;
  DateTime? lastCompletion;
  DateTime? lastMissed;

  StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalXP,
    this.lastCompletion,
    this.lastMissed,
  });

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'totalXP': totalXP,
        'lastCompletion': lastCompletion?.toIso8601String(),
        'lastMissed': lastMissed?.toIso8601String(),
      };

  factory StreakData.fromJson(Map<String, dynamic> json) => StreakData(
        currentStreak: json['currentStreak'] ?? 0,
        longestStreak: json['longestStreak'] ?? 0,
        totalXP: json['totalXP'] ?? 0,
        lastCompletion: json['lastCompletion'] != null
            ? DateTime.tryParse(json['lastCompletion'])
            : null,
        lastMissed: json['lastMissed'] != null
            ? DateTime.tryParse(json['lastMissed'])
            : null,
      );
}

