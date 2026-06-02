import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Theme State ──
  static final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(
    true,
  );

  static bool get isDark => isDarkModeNotifier.value;
  static set isDark(bool val) {
    isDarkModeNotifier.value = val;
  }

  // ── Core Palette ──
  static Color get primaryDark =>
      isDark ? const Color(0xFF0D1F2D) : const Color(0xFFF8FAFC);
  static Color get primaryMedium =>
      isDark ? const Color(0xFF152232) : const Color(0xFFF1F5F9);
  static Color get armyGreen => const Color(0xFF4A7C6B);
  static Color get armyGreenDark => const Color(0xFF3A6357);
  static Color get armyGreenLight =>
      isDark ? const Color(0xFF213A34) : const Color(0xFFDEF7EC);

  // ── Accent Colors ──
  static Color get accentOrange =>
      isDark ? const Color(0xFFFFA726) : const Color(0xFFF59E0B);
  static Color get accentBlue =>
      isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6);
  static Color get accentRed => const Color(0xFF8B3A3A);

  // ── Surface & Background ──
  static Color get background =>
      isDark ? const Color(0xFF0D1F2D) : const Color(0xFFF5F8FA);
  static Color get surface =>
      isDark ? const Color(0xFF1A2E3B) : const Color(0xFFFFFFFF);
  static Color get surfaceAlt =>
      isDark ? const Color(0xFF132330) : const Color(0xFFF8FAFC);
  static Color get surfaceCard =>
      isDark ? const Color(0xFF1A2E3B) : const Color(0xFFFEFEFE);
  static Color get navSurface =>
      isDark ? const Color(0xFF0F1C28) : const Color(0xFFFFFFFF);

  // ── Home Page Specific ──
  static Color get cardDark => isDark ? const Color(0xFF1A3A5C) : Colors.white;
  static Color get btnGreen => const Color(0xFF2ECC8A);
  static Color get btnGreenDark => const Color(0xFF1FAF72);
  static Color get btnRed => const Color(0xFFE53935);
  static Color get ringColor => isDark
      ? const Color(0xFF2ECC8A)
      : const Color(0xFF2ECC8A).withValues(alpha: 0.4);
  static Color get dividerColor =>
      isDark ? const Color(0xFF1E4060) : const Color(0xFFE2E8F0);

  // ── Text ──
  static Color get textDark => isDark ? Colors.white : const Color(0xFF0F172A);
  static Color get textMuted =>
      isDark ? const Color(0xFF7A9BAD) : const Color(0xFF64748B);
  static Color get textLight =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8);

  // ── Semantic Colors ──
  static Color get success =>
      isDark ? const Color(0xFF22C55E) : const Color(0xFF16A34A);
  static Color get warning =>
      isDark ? const Color(0xFFFFA726) : const Color(0xFFF59E0B);
  static Color get error =>
      isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626);
  static Color get info =>
      isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6);

  // ── Border ──
  static Color get border =>
      isDark ? const Color(0xFF1E3545) : const Color(0xFFE5E7EB);
  static Color get borderLight =>
      isDark ? const Color(0xFF1E3545) : const Color(0xFFF3F4F6);

  // ── Gradients ──
  static List<Color> get gradientPrimary => isDark
      ? [
          const Color(0xFF0D1F2D),
          const Color(0xFF152232),
          const Color(0xFF1A2E3B),
        ]
      : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9), Colors.white];

  static const List<Color> gradientArmyGreen = [
    Color(0xFF4A7C6B),
    Color(0xFF3A6357),
  ];

  static const List<Color> gradientError = [
    Color(0xFFEF4444),
    Color(0xFF8B3A3A),
  ];

  // ── Shadows ──
  static BoxShadow get cardShadow => BoxShadow(
    color: isDark
        ? Colors.black.withValues(alpha: 0.16)
        : Colors.black.withValues(alpha: 0.05),
    blurRadius: 18,
    offset: const Offset(0, 8),
  );

  static BoxShadow get buttonShadow => BoxShadow(
    color: armyGreen.withValues(alpha: 0.28),
    blurRadius: 18,
    offset: const Offset(0, 8),
  );

  // ── Helpers ──
  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'SELAMAT PAGI';
    if (hour < 15) return 'SELAMAT SIANG';
    if (hour < 18) return 'SELAMAT SORE';
    return 'SELAMAT MALAM';
  }
}
