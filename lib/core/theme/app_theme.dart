import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF2E7D6B);
  static const secondary = Color(0xFFFFB84D);
  static const tertiary = Color(0xFF7C5CFF);
  static const success = Color(0xFF3FA34D);
  static const warning = Color(0xFFF2A100);
  static const error = Color(0xFFD64545);
  static const surface = Color(0xFFFAFAF7);
  static const onSurface = Color(0xFF1B1F1D);

  static ThemeData light() => _theme(Brightness.light);

  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: dark ? const Color(0xFF6FD3BC) : primary,
      brightness: brightness,
      primary: dark ? const Color(0xFF6FD3BC) : primary,
      secondary: dark ? const Color(0xFFFFCF85) : secondary,
      tertiary: dark ? const Color(0xFFB7A4FF) : tertiary,
      error: dark ? const Color(0xFFFF8A8A) : error,
      surface: dark ? const Color(0xFF121614) : surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        color: dark ? const Color(0xFF1B2220) : Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
      ),
      textTheme: Typography.material2021().black.apply(
        bodyColor: dark ? const Color(0xFFE6EAE8) : onSurface,
        displayColor: dark ? const Color(0xFFE6EAE8) : onSurface,
      ),
    );
  }
}
