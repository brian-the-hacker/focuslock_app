import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.register(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (result['access_token'] != null) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
        }
      } else {
        setState(() { _error = result['detail'] ?? 'Registration failed'; });
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
      appBar: AppBar(title: const Text('CREATE ACCOUNT', style: TextStyle(letterSpacing: 3))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const SizedBox(height: 24),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username',
                  border: OutlineInputBorder(borderRadius: BorderRadius.zero)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.zero)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.zero)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: primary, fontSize: 12)),
              ],
              const SizedBox(height: 24),
              SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('CREATE ACCOUNT', style: TextStyle(letterSpacing: 4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}