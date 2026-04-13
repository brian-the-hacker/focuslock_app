class Stats {
  final String username;
  final double balance;
  final double totalEarned;
  final double totalLost;
  final int totalSessions;
  final int completed;
  final int interrupted;
  final int totalMinutes;
  final int currentStreak;
  final int longestStreak;

  Stats({
    required this.username,
    required this.balance,
    required this.totalEarned,
    required this.totalLost,
    required this.totalSessions,
    required this.completed,
    required this.interrupted,
    required this.totalMinutes,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory Stats.fromJson(Map<String, dynamic> json) => Stats(
        username: json['username'],
        balance: (json['balance'] ?? 0).toDouble(),
        totalEarned: (json['total_earned'] ?? 0).toDouble(),
        totalLost: (json['total_lost'] ?? 0).toDouble(),
        totalSessions: json['total_sessions'] ?? 0,
        completed: json['completed'] ?? 0,
        interrupted: json['interrupted'] ?? 0,
        totalMinutes: json['total_minutes'] ?? 0,
        currentStreak: json['current_streak'] ?? 0,
        longestStreak: json['longest_streak'] ?? 0,
      );
}