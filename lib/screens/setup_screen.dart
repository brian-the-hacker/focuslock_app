import 'package:flutter/material.dart';
import '../services/vpn_service.dart';
import '../services/session_storage.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with WidgetsBindingObserver {
  bool _accessibilityDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Auto-refresh when user comes back from accessibility settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    final acc = await VpnKillService.isAccessibilityEnabled();
    if (mounted) setState(() => _accessibilityDone = acc);
  }

  Future<void> _done() async {
    await SessionStorage.markSetupComplete();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('SETUP', style: TextStyle(
                fontSize: 36, fontWeight: FontWeight.bold,
                color: primary, letterSpacing: 6)),
              const SizedBox(height: 8),
              const Text('One-time setup. You will not see this again.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 48),

              // Step 1 — VPN
              _stepTile(
                number: '1',
                title: 'VPN Permission',
                subtitle: 'Granted automatically when you start your first session.',
                done: true,
                onTap: null,
              ),
              const SizedBox(height: 16),

              // Step 2 — Accessibility
              _stepTile(
                number: '2',
                title: 'Accessibility Permission',
                subtitle: _accessibilityDone
                  ? 'Enabled ✓ — VPN settings blocked during sessions.'
                  : 'Tap here → find "Focus Lock" → toggle ON.\nComes back here automatically.',
                done: _accessibilityDone,
                onTap: () async {
                  await VpnKillService.openAccessibilitySettings();
                },
              ),
              const SizedBox(height: 48),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: const Text(
                  'These permissions never collect your data.\n'
                  'VPN blocks internet for all apps except Focus Lock.\n'
                  'Accessibility closes Settings if opened during a session.',
                  style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.6),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _done,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: _accessibilityDone
                        ? primary
                        : Colors.grey.shade700,
                  ),
                  child: Text(
                    _accessibilityDone ? 'GET STARTED 🔒' : 'SKIP FOR NOW',
                    style: const TextStyle(letterSpacing: 3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepTile({
    required String number,
    required String title,
    required String subtitle,
    required bool done,
    required VoidCallback? onTap,
  }) {
    final primary = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: done ? Colors.green
                : (onTap != null ? primary : Colors.grey.shade800),
            width: done ? 1.5 : 1,
          ),
          color: done
              ? Colors.green.withOpacity(0.05)
              : Colors.transparent,
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? Colors.green : primary,
            ),
            child: Center(
              child: Text(
                done ? '✓' : number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(
                color: Colors.grey, fontSize: 11, height: 1.4)),
            ],
          )),
          if (onTap != null && !done)
            Icon(Icons.arrow_forward_ios,
              size: 14, color: Colors.grey.shade600),
        ]),
      ),
    );
  }
}