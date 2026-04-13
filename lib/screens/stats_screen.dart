import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/stats.dart';
import '../models/session.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Stats? _stats;
  List<Session> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stats   = await ApiService.getStats();
      final history = await ApiService.getHistory();
      setState(() { _stats = stats; _history = history; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_stats == null) return const Center(child: Text('Could not load stats'));

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('STATS', style: TextStyle(fontSize: 10, letterSpacing: 4, color: Colors.grey)),
            const SizedBox(height: 16),

            // Coin balance
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: primary),
                color: primary.withOpacity(0.05),
              ),
              child: Column(children: [
                Text('💰 BALANCE', style: TextStyle(
                  fontSize: 10, letterSpacing: 3, color: Colors.grey)),
                const SizedBox(height: 8),
                Text('${_stats!.balance.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold,
                    color: primary, letterSpacing: 4)),
                const Text('coins', style: TextStyle(color: Colors.grey, letterSpacing: 2)),
              ]),
            ),
            const SizedBox(height: 16),

            // Stats grid
            Row(children: [
              Expanded(child: _statBox('✅ Completed', '${_stats!.completed}')),
              const SizedBox(width: 8),
              Expanded(child: _statBox('❌ Interrupted', '${_stats!.interrupted}')),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _statBox('⏱ Total time', '${_stats!.totalMinutes} min')),
              const SizedBox(width: 8),
              Expanded(child: _statBox('🔥 Streak', '${_stats!.currentStreak} days')),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _statBox('📈 Earned', '${_stats!.totalEarned.toStringAsFixed(1)}')),
              const SizedBox(width: 8),
              Expanded(child: _statBox('📉 Lost', '${_stats!.totalLost.toStringAsFixed(1)}')),
            ]),
            const SizedBox(height: 24),

            // History
            Text('RECENT SESSIONS',
              style: TextStyle(fontSize: 10, letterSpacing: 4, color: Colors.grey)),
            const SizedBox(height: 12),
            ..._history.map((s) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: Row(children: [
                Text(s.completed ? '✅' : '❌', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${s.durationMins} min — ${s.mode}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('${s.startedAt.toString().substring(0, 16)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ])),
                Text(s.completed ? '+${s.coinsEarned.toStringAsFixed(1)}' : '-${s.coinsLost.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: s.completed ? Colors.green : primary,
                    fontWeight: FontWeight.bold,
                  )),
              ]),
            )),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade800)),
      child: Column(children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}