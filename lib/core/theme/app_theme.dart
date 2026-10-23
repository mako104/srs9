import 'package:flutter/material.dart';

class AppTheme {
  static const pink = Color(0xFFE91E63);
  static const softPink = Color(0xFFFFF0F5);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: pink,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: softPink,
      appBarTheme: const AppBarTheme(
        backgroundColor: pink,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: pink,
        foregroundColor: Colors.white,
      ),
    );
  }
}