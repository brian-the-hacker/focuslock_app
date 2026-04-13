import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'auth/login_screen.dart';
import 'session_screen.dart';
import 'stats_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedDuration = 25;
  String _selectedMode  = 'hybrid';
  String _username      = '';
  double _balance       = 0;
  int _streak           = 0;
  bool _loading         = false;
  int _currentIndex     = 0;

  final List<int> _durations = [1, 5, 15, 25, 30, 45, 60, 90, 120];
  final Map<String, String> _modes = {
    'internet': '🌐  Internet only',
    'apps':     '📱  Apps only',
    'hybrid':   '🔒  Hybrid (recommended)',
  };

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final username = await ApiService.getUsername();
    try {
      final stats = await ApiService.getStats();
      setState(() {
        _username = username ?? '';
        _balance  = stats.balance;
        _streak   = stats.currentStreak;
      });
    } catch (e) {
      print('DEBUG: _loadUser error: $e');
      setState(() { _username = username ?? ''; });
    }
  }

  Future<void> _startSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        duration: _selectedDuration,
        mode: _selectedMode,
      ),
    );

    if (confirmed != true) return;

    setState(() { _loading = true; });
    try {
      print('DEBUG: Starting session duration=$_selectedDuration mode=$_selectedMode');
      final result = await ApiService.startSession(_selectedDuration, _selectedMode);
      print('DEBUG: startSession response = $result');

      if (result['session_id'] != null && mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => SessionScreen(
            sessionId:    result['session_id'],
            durationMins: _selectedDuration,
            mode:         _selectedMode,
            previewCoins: (result['preview_coins'] ?? 0).toDouble(),
          ),
        )).then((_) => _loadUser());
      } else {
        print('DEBUG: No session_id — full response: $result');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${result['detail'] ?? result.toString()}')));
        }
      }
    } catch (e) {
      print('DEBUG: _startSession exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
      }
    }
    setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_buildHome(), const StatsScreen(), const LeaderboardScreen()];
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.lock), label: 'Lock'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Leaderboard'),
        ],
      ),
    );
  }

  Widget _buildHome() {
    final primary = Theme.of(context).primaryColor;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('FOCUS LOCK', style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold,
                    color: primary, letterSpacing: 4)),
                  Text('Welcome back, $_username',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ]),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await ApiService.logout();
                    if (mounted) Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats bar
            Row(children: [
              _statChip('💰', '${_balance.toStringAsFixed(1)} coins'),
              const SizedBox(width: 12),
              _statChip('🔥', '$_streak day streak'),
            ]),
            const SizedBox(height: 32),

            // Duration picker
            Text('DURATION', style: TextStyle(
              fontSize: 10, letterSpacing: 3, color: Colors.grey)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _durations.map((d) {
                final selected = d == _selectedDuration;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDuration = d),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? primary : Colors.transparent,
                      border: Border.all(
                          color: selected ? primary : Colors.grey.shade700),
                    ),
                    child: Text(
                      d >= 60
                          ? '${d ~/ 60}h${d % 60 > 0 ? " ${d % 60}m" : ""}'
                          : '${d}m',
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Mode picker
            Text('MODE', style: TextStyle(
              fontSize: 10, letterSpacing: 3, color: Colors.grey)),
            const SizedBox(height: 12),
            ..._modes.entries.map((e) {
              final selected = e.key == _selectedMode;
              return GestureDetector(
                onTap: () => setState(() => _selectedMode = e.key),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selected ? primary.withOpacity(0.1) : Colors.transparent,
                    border: Border.all(
                        color: selected ? primary : Colors.grey.shade700),
                  ),
                  child: Text(e.value,
                    style: TextStyle(color: selected ? primary : Colors.grey)),
                ),
              );
            }),

            const SizedBox(height: 32),

            // Lock button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _startSession,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: primary,
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('🔒  LOCK IN',
                        style: TextStyle(fontSize: 18, letterSpacing: 4)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Text('$icon  $label', style: const TextStyle(fontSize: 12)),
    );
  }
}

class _ConfirmDialog extends StatefulWidget {
  final int duration;
  final String mode;
  const _ConfirmDialog({required this.duration, required this.mode});

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  final _controller = TextEditingController();
  bool _wrong = false;

  String get _durationStr {
    if (widget.duration >= 60) {
      final h = widget.duration ~/ 60;
      final m = widget.duration % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    return '${widget.duration} min';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return AlertDialog(
      title: Text('⚠️ CONFIRM LOCK',
        style: TextStyle(color: primary, letterSpacing: 2)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Duration: $_durationStr',
            style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Mode: ${widget.mode}'),
          const SizedBox(height: 16),
          const Text(
            'Once locked, there is NO exit until timer ends.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text('Type LOCK to confirm:',
            style: TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero),
              hintText: 'LOCK',
              errorText: _wrong ? 'Type LOCK in capitals' : null,
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.trim() == 'LOCK') {
              Navigator.pop(context, true);
            } else {
              setState(() => _wrong = true);
            }
          },
          child: const Text('LOCK IN'),
        ),
      ],
    );
  }
}