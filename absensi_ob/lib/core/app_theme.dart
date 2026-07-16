import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  AppTheme._();

  static const String _themeKey = 'is_dark_mode';

  static const Duration fastTransition = Duration(milliseconds: 220);
  static const Duration normalTransition = Duration(milliseconds: 300);
  static const Curve transitionCurve = Curves.easeOutCubic;

  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;

  static final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(
    false,
  );

  static bool get isDark => isDarkModeNotifier.value;
  static set isDark(bool value) => setDarkMode(value);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkModeNotifier.value = prefs.getBool(_themeKey) ?? false;
  }

  static Future<void> setDarkMode(bool value) async {
    if (isDarkModeNotifier.value == value) return;
    isDarkModeNotifier.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, value);
  }

  static Color get clayBackground =>
      isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA);
  static Color get claySurface =>
      isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
  static Color get claySurfaceAlt =>
      isDark ? const Color(0xFF242428) : const Color(0xFFF8FAFC);
  static Color get clayPrimary =>
      isDark ? const Color(0xFF6EA8FF) : const Color(0xFF5B8DEF);
  static Color get claySecondary =>
      isDark ? const Color(0xFF90CAF9) : const Color(0xFF7CC6FE);
  static Color get clayAccent =>
      isDark ? const Color(0xFF5FD3BC) : const Color(0xFF8DD7BF);
  static Color get clayText =>
      isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1F2937);
  static Color get clayTextMuted =>
      isDark ? const Color(0xFFC8CDD4) : const Color(0xFF6B7280);
  static Color get clayHighlight => isDark
      ? Colors.white.withValues(alpha: 0.05)
      : Colors.white.withValues(alpha: 0.90);
  static Color get clayShadow => isDark
      ? Colors.black.withValues(alpha: 0.35)
      : Colors.black.withValues(alpha: 0.08);

  static Color get primaryDark => clayBackground;
  static Color get primaryMedium => claySurface;
  static Color get armyGreen => clayPrimary;
  static Color get armyGreenDark =>
      isDark ? const Color(0xFF4C8DF5) : const Color(0xFF4078E8);
  static Color get armyGreenLight =>
      isDark ? clayPrimary.withValues(alpha: 0.16) : const Color(0xFFEAF2FF);

  static Color get accentOrange =>
      isDark ? const Color(0xFFFFA726) : const Color(0xFFF59E0B);
  static Color get accentBlue => claySecondary;
  static Color get accentRed => const Color(0xFFE65B5B);

  static Color get background => clayBackground;
  static Color get surface => claySurface;
  static Color get surfaceAlt => claySurfaceAlt;
  static Color get surfaceCard => claySurface;
  static Color get navSurface => claySurface;

  static Color get cardDark => claySurface;
  static Color get btnGreen => clayAccent;
  static Color get btnGreenDark =>
      isDark ? const Color(0xFF2FB9A2) : const Color(0xFF59C8AA);
  static Color get btnRed => const Color(0xFFE65B5B);
  static Color get ringColor =>
      isDark ? clayAccent : clayAccent.withValues(alpha: 0.4);
  static Color get dividerColor =>
      isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);

  static Color get textDark => clayText;
  static Color get textMuted => clayTextMuted;
  static Color get textLight =>
      isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF);

  static Color get success =>
      isDark ? const Color(0xFF5FD3BC) : const Color(0xFF2FBF86);
  static Color get warning =>
      isDark ? const Color(0xFFFFA726) : const Color(0xFFF59E0B);
  static Color get error =>
      isDark ? const Color(0xFFFF6B6B) : const Color(0xFFE65B5B);
  static Color get info => clayPrimary;

  static Color get border =>
      isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE9EEF5);
  static Color get borderLight =>
      isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF3F6FA);

  static List<Color> get gradientPrimary => isDark
      ? [
          const Color(0xFF121212),
          const Color(0xFF1C1C1E),
          const Color(0xFF23272D),
        ]
      : [const Color(0xFFF5F7FA), const Color(0xFFEAF2FF), Colors.white];

  static List<Color> get gradientArmyGreen => isDark
      ? [const Color(0xFF6EA8FF), const Color(0xFF5FD3BC)]
      : [const Color(0xFF5B8DEF), const Color(0xFF8DD7BF)];

  static const List<Color> gradientError = [
    Color(0xFFFF7A7A),
    Color(0xFFE65B5B),
  ];

  static BoxShadow get cardShadow => BoxShadow(
    color: clayShadow,
    blurRadius: 24,
    spreadRadius: -8,
    offset: const Offset(0, 14),
  );

  static BoxShadow get highlightShadow => BoxShadow(
    color: clayHighlight,
    blurRadius: 12,
    spreadRadius: -10,
    offset: const Offset(-6, -6),
  );

  static BoxShadow get buttonShadow => BoxShadow(
    color: clayPrimary.withValues(alpha: isDark ? 0.22 : 0.28),
    blurRadius: 22,
    spreadRadius: -6,
    offset: const Offset(0, 12),
  );

  static BoxDecoration clayDecoration({
    Color? color,
    double radius = radiusXl,
    bool withBorder = true,
  }) {
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: BorderRadius.circular(radius),
      border: withBorder ? Border.all(color: border) : null,
      boxShadow: [cardShadow, highlightShadow],
    );
  }

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final textTheme = GoogleFonts.plusJakartaSansTextTheme();
    final scheme = ColorScheme(
      brightness: brightness,
      primary: dark ? const Color(0xFF6EA8FF) : const Color(0xFF5B8DEF),
      onPrimary: Colors.white,
      secondary: dark ? const Color(0xFF90CAF9) : const Color(0xFF7CC6FE),
      onSecondary: dark ? const Color(0xFF111827) : const Color(0xFF1F2937),
      tertiary: dark ? const Color(0xFF5FD3BC) : const Color(0xFF8DD7BF),
      onTertiary: dark ? const Color(0xFF111827) : const Color(0xFF1F2937),
      error: dark ? const Color(0xFFFF6B6B) : const Color(0xFFE65B5B),
      onError: Colors.white,
      surface: dark ? const Color(0xFF1C1C1E) : Colors.white,
      onSurface: dark ? const Color(0xFFF5F5F5) : const Color(0xFF1F2937),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      textTheme: textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF242428) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(
            color: dark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE9EEF5),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      visualDensity: VisualDensity.standard,
    );
  }

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'SELAMAT PAGI';
    if (hour < 15) return 'SELAMAT SIANG';
    if (hour < 18) return 'SELAMAT SORE';
    return 'SELAMAT MALAM';
  }
}
