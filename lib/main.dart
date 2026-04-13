import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FocusLockApp());
}

class FocusLockApp extends StatelessWidget {
  const FocusLockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus Lock',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      home: const SplashScreen(),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      primaryColor: const Color(0xFFFF2D2D),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFF2D2D),
        secondary: Color(0xFFFF8C00),
        surface: Color(0xFF141414),
        error: Color(0xFFFF2D2D),
      ),
      fontFamily: 'monospace',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF2D2D),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      primaryColor: const Color(0xFFFF2D2D),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFFF2D2D),
        secondary: Color(0xFFFF8C00),
        surface: Colors.white,
      ),
      fontFamily: 'monospace',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F5F5),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF2D2D),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}