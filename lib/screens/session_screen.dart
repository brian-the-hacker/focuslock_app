import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/vpn_service.dart';
import '../services/session_storage.dart';

class SessionScreen extends StatefulWidget {
  final int sessionId;
  final int durationMins;
  final String mode;
  final double previewCoins;
  final int endTimeMs; // absolute end time — 0 means calculate from durationMins

  const SessionScreen({
    super.key,
    required this.sessionId,
    required this.durationMins,
    required this.mode,
    required this.previewCoins,
    this.endTimeMs = 0,
  });

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late int _totalSeconds;
  late int _remainingSeconds;
  Timer? _timer;
  bool _completed = false;
  bool _requestingExit = false;
  final _reasonController = TextEditingController();

  final List<String> _quotes = [
    "The scroll urge will pass. It always does.",
    "Boredom is where your best ideas live.",
    "Your future self is watching right now.",
    "Deep work = deep results. Keep going.",
    "Nothing on that feed is worth your time.",
    "You locked in because you trust yourself.",
    "Every minute here is a win.",
    "The algorithm wants your attention. Don't give it.",
  ];

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.durationMins * 60;

    // If resuming a session, calculate remaining seconds from absolute end time
    if (widget.endTimeMs > 0) {
      final remaining = widget.endTimeMs - DateTime.now().millisecondsSinceEpoch;
      _remainingSeconds = (remaining / 1000).round().clamp(0, _totalSeconds);
    } else {
      _remainingSeconds = _totalSeconds;
    }

    _startVpn();
    _startTimer();
  }

  Future<void> _startVpn() async {
    if (widget.mode == 'internet' || widget.mode == 'hybrid') {
      final endTimeMs = widget.endTimeMs > 0
          ? widget.endTimeMs
          : DateTime.now()
              .add(Duration(minutes: widget.durationMins))
              .millisecondsSinceEpoch;

      // Save session for memory recovery
      await SessionStorage.saveSession(
        sessionId:    widget.sessionId,
        durationMins: widget.durationMins,
        mode:         widget.mode,
        previewCoins: widget.previewCoins,
        endTimeMs:    endTimeMs,
      );

      await VpnKillService.requestPermissionAndStart(endTimeMs: endTimeMs);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 0) {
        t.cancel();
        _finishSession();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  Future<void> _finishSession() async {
    setState(() => _completed = true);
    _timer?.cancel();
    await VpnKillService.stop();
    await SessionStorage.clearSession(); // ← add this
    
    print('DEBUG: Calling completeSession for session ${widget.sessionId}');
    try {
      final result = await ApiService.completeSession(widget.sessionId, true);
      print('DEBUG: Result = $result');
      if (mounted) _showCompletionDialog(result);
    } catch (e) {
      print('DEBUG: Error = $e');
    }
  }

  void _showCompletionDialog(Map<String, dynamic>? result) {
    final coins   = result?['coins_earned'] ?? widget.previewCoins;
    final balance = result?['new_balance'] ?? 0;
    final streak  = result?['streak'] ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🏆 SESSION COMPLETE',
            style: TextStyle(letterSpacing: 2)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('+$coins coins earned!',
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Balance: $balance coins',
              style: const TextStyle(color: Colors.amber)),
          const SizedBox(height: 4),
          Text('🔥 Streak: $streak days'),
          const SizedBox(height: 12),
          const Text('Well done. Keep it going.'),
        ]),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('DONE'),
          ),
        ],
      ),
    );
  }

  // ── Emergency exit request ────────────────────────────────
  void _showEmergencyExitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('⚠️ Emergency Exit Request',
            style: TextStyle(fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
            'This will send a request to the admin.\n'
            'Only genuine emergencies are approved.\n'
            'You will lose coins if approved.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason for exit',
              hintText: 'Explain your emergency...',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: _requestingExit ? null : _submitExitRequest,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange),
            child: _requestingExit
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('SEND REQUEST'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitExitRequest() async {
    if (_reasonController.text.trim().isEmpty) return;
    setState(() => _requestingExit = true);

    try {
      final result = await ApiService.requestEmergencyExit(
        widget.sessionId,
        _reasonController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        if (result['request_id'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📨 Request sent. Wait for admin to send you a code.'),
              duration: Duration(seconds: 5),
            ),
          );
          // Show code entry dialog
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) _showCodeEntryDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['detail'] ?? 'Failed to send request')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server unreachable')));
      }
    }

    setState(() => _requestingExit = false);
  }

  void _showCodeEntryDialog() {
    final codeController = TextEditingController();
    bool submitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Enter Admin Code',
            style: TextStyle(fontSize: 16)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text(
              'Once admin approves your request,\nenter the code they send you.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold,
                  letterSpacing: 8),
              decoration: const InputDecoration(
                hintText: 'XXXXXX',
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              ),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('WAIT'),
            ),
            ElevatedButton(
              onPressed: submitting ? null : () async {
                if (codeController.text.trim().isEmpty) return;
                setS(() => submitting = true);

                try {
                  final result = await ApiService.redeemEmergencyCode(
                    widget.sessionId,
                    codeController.text.trim(),
                  );

                  if (result['success'] == true) {
                    await VpnKillService.stop();
                    if (mounted) {
                      Navigator.pop(ctx);
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => AlertDialog(
                          title: const Text('Session Ended'),
                          content: Text(
                            'Penalty: -${result['penalty']} coins\n'
                            'Balance: ${result['new_balance']} coins'),
                          actions: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  } else {
                    setS(() => submitting = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(
                        result['detail'] ?? 'Invalid or expired code')));
                  }
                } catch (e) {
                  setS(() => submitting = false);
                }
              },
              child: submitting
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('SUBMIT CODE'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _reasonController.dispose();
    // Note: we do NOT stop VPN here
    // The background service keeps running even when screen is closed
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  String get _timeString {
    final h = _remainingSeconds ~/ 3600;
    final m = (_remainingSeconds % 3600) ~/ 60;
    final s = _remainingSeconds % 60;
    return h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => 1 - (_remainingSeconds / _totalSeconds);

  String get _quote {
    final elapsed = _totalSeconds - _remainingSeconds;
    return _quotes[(elapsed ~/ 30) % _quotes.length];
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      // No PopScope — user can freely go home
      // VPN keeps running in background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              Text('🔒 FOCUS LOCK — ACTIVE',
                  style: TextStyle(
                      color: primary,
                      letterSpacing: 3,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'You can go home — internet stays off',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 48),

              // Progress ring
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(alignment: Alignment.center, children: [
                  CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 8,
                    color: primary,
                    backgroundColor: Colors.grey.shade800,
                  ),
                  Text(_timeString,
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: primary,
                          letterSpacing: 4)),
                ]),
              ),
              const SizedBox(height: 32),

              // Mode status
              Text(
                widget.mode == 'internet'
                    ? 'WiFi OFF | Data OFF | Calls ✓'
                    : widget.mode == 'apps'
                        ? 'Apps frozen | Internet normal'
                        : 'WiFi OFF | Data OFF | Apps frozen',
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12, letterSpacing: 1),
              ),
              const SizedBox(height: 8),

              // Coins preview
              Text('🏆 Complete to earn ${widget.previewCoins} coins',
                  style:
                      const TextStyle(color: Colors.amber, fontSize: 12)),
              const SizedBox(height: 32),

              // Quote
              Text('"$_quote"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontStyle: FontStyle.italic)),

              const Spacer(),

              // Emergency exit — subtle, at the bottom
              TextButton(
                onPressed: _showEmergencyExitDialog,
                child: Text(
                  'Request Emergency Exit',
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}