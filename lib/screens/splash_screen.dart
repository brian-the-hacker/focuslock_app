import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'auth/login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    final loggedIn = await ApiService.isLoggedIn();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => loggedIn ? const HomeScreen() : const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FOCUS LOCK',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No escape. No excuses.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}