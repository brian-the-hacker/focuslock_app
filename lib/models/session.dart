class Session {
  final int id;
  final int durationMins;
  final String mode;
  final bool completed;
  final double coinsEarned;
  final double coinsLost;
  final DateTime startedAt;

  Session({
    required this.id,
    required this.durationMins,
    required this.mode,
    required this.completed,
    required this.coinsEarned,
    required this.coinsLost,
    required this.startedAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: json['id'],
        durationMins: json['duration_mins'],
        mode: json['mode'],
        completed: json['completed'],
        coinsEarned: (json['coins_earned'] ?? 0).toDouble(),
        coinsLost: (json['coins_lost'] ?? 0).toDouble(),
        startedAt: DateTime.parse(json['started_at']),
      );
}