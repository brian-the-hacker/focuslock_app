import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _board = [];
  bool _loading = true;
  String _myUsername = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final username = await ApiService.getUsername();
    try {
      final board = await ApiService.getLeaderboard();
      setState(() {
        _board      = board;
        _myUsername = username ?? '';
        _loading    = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('LEADERBOARD',
              style: TextStyle(fontSize: 10, letterSpacing: 4, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Top focus earners',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 24),

            if (_board.isEmpty)
              const Center(child: Text('No data yet. Be the first!'))
            else
              ..._board.map((entry) {
                final rank     = entry['rank'] as int;
                final username = entry['username'] as String;
                final balance  = (entry['balance'] as num).toDouble();
                final isMe     = username == _myUsername;
                final medals   = ['🥇', '🥈', '🥉'];
                final medal    = rank <= 3 ? medals[rank - 1] : '$rank.';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isMe ? primary : Colors.grey.shade800,
                      width: isMe ? 2 : 1,
                    ),
                    color: isMe ? primary.withOpacity(0.05) : Colors.transparent,
                  ),
                  child: Row(children: [
                    Text(medal, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 16),
                    Expanded(child: Text(
                      username + (isMe ? ' (you)' : ''),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isMe ? primary : null,
                      ),
                    )),
                    Text('${balance.toStringAsFixed(1)} 💰',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isMe ? primary : Colors.amber,
                      )),
                  ]),
                );
              }),
          ],
        ),
      ),
    );
  }
}