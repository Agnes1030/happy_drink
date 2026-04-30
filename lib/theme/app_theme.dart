import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFFFBF9F5);
  static const Color primary = Color(0xFF3A6544);
  static const Color secondary = Color(0xFF725A43);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1B1C1A);
  static const Color textSecondary = Color(0xFF414941);
  static const Color outline = Color(0xFFC1C9BF);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Public Sans',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFDFCF0),
        foregroundColor: primary,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F3EF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outline),
        ),
      ),
    );
  }
}
