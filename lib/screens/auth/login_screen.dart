import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      if (result['access_token'] != null) {
        if (mounted) {
          Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
      } else {
        setState(() { _error = result['detail'] ?? 'Login failed'; });
      }
    } catch (e) {
      setState(() { _error = 'Server unreachable'; });
    }
    setState(() { _loading = false; });
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
              const SizedBox(height: 48),
              Text('FOCUS\nLOCK',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold,
                  color: primary, letterSpacing: 4, height: 1.1)),
              const SizedBox(height: 8),
              const Text('No escape. No excuses.',
                style: TextStyle(color: Colors.grey, letterSpacing: 2, fontSize: 12)),
              const SizedBox(height: 64),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username',
                  border: OutlineInputBorder(borderRadius: BorderRadius.zero)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.zero)),
                onSubmitted: (_) => _login(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: primary, fontSize: 12)),
              ],
              const SizedBox(height: 24),
              SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('LOCK IN', style: TextStyle(letterSpacing: 4)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text("Don't have an account? Register"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}