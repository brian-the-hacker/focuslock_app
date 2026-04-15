import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_storage.dart';
import '../services/vpn_service.dart';
import 'auth/login_screen.dart';
import 'home_screen.dart';
import 'session_screen.dart';
import 'setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 800));

    final loggedIn = await ApiService.isLoggedIn();
    if (!loggedIn) {
      _go(const LoginScreen());
      return;
    }

    // Check for active session first (memory recovery)
    final activeSession = await SessionStorage.getActiveSession();
    if (activeSession != null) {
      // Resume session
      final endTimeMs   = activeSession['end_time_ms'] as int;
      final remaining   = endTimeMs - DateTime.now().millisecondsSinceEpoch;
      final remainMins  = (remaining / 60000).ceil();

      // Restart VPN if not running
      if (!VpnKillService.isRunningSync) {
        await VpnKillService.requestPermissionAndStart(endTimeMs: endTimeMs);
      }

      _go(SessionScreen(
        sessionId:    activeSession['session_id'],
        durationMins: remainMins,
        mode:         activeSession['mode'],
        previewCoins: activeSession['preview_coins'],
        endTimeMs:    endTimeMs, // pass absolute end time
      ));
      return;
    }

    // Check if setup is complete
    final setupDone = await SessionStorage.isSetupComplete();
    if (!setupDone) {
      _go(const SetupScreen());
      return;
    }

    // Check if accessibility is still enabled (remind if not)
    final accEnabled = await VpnKillService.isAccessibilityEnabled();
    if (!accEnabled) {
      _go(const SetupScreen()); // show setup again as reminder
      return;
    }

    _go(const HomeScreen());
  }

  void _go(Widget screen) {
    if (mounted) {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => screen));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('FOCUS LOCK',
              style: TextStyle(
                fontSize: 36, fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor, letterSpacing: 8)),
            const SizedBox(height: 8),
            const Text('No escape. No excuses.',
              style: TextStyle(color: Colors.grey, letterSpacing: 2, fontSize: 12)),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              color: Theme.of(context).primaryColor, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}