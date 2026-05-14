import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryDark = Color(0xFF0D1F2D);
  static const Color primaryMedium = Color(0xFF152232);
  static const Color armyGreen = Color(0xFF4A7C6B);
  static const Color armyGreenDark = Color(0xFF3A6357);
  static const Color armyGreenLight = Color(0xFF213A34);

  static const Color accentOrange = Color(0xFFFFA726);
  static const Color accentRed = Color(0xFF8B3A3A);

  static const Color background = Color(0xFF0D1F2D);
  static const Color surface = Color(0xFF1A2E3B);
  static const Color surfaceAlt = Color(0xFF132330);
  static const Color navSurface = Color(0xFF0F1C28);

  static const Color textDark = Colors.white;
  static const Color textMuted = Color(0xFF7A9BAD);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF60A5FA);

  static const Color border = Color(0xFF1E3545);

  static const List<Color> gradientPrimary = [
    Color(0xFF0D1F2D),
    Color(0xFF152232),
    Color(0xFF1A2E3B),
  ];

  static const List<Color> gradientArmyGreen = [
    Color(0xFF4A7C6B),
    Color(0xFF3A6357),
  ];

  static const List<Color> gradientError = [
    Color(0xFFEF4444),
    Color(0xFF8B3A3A),
  ];

  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.16),
    blurRadius: 18,
    offset: const Offset(0, 8),
  );

  static BoxShadow buttonShadow = BoxShadow(
    color: armyGreen.withValues(alpha: 0.28),
    blurRadius: 18,
    offset: const Offset(0, 8),
  );
}
