import 'package:absensi_ob/pages/login_page.dart';
import 'package:absensi_ob/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppTheme.isDarkModeNotifier,
      builder: (context, isDark, child) {
        final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

        return MaterialApp(
          title: 'Absensi OB',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
            textTheme: baseTextTheme.apply(
              bodyColor: AppTheme.textDark,
              displayColor: AppTheme.textDark,
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.armyGreen,
              brightness: isDark ? Brightness.dark : Brightness.light,
              surface: AppTheme.surface,
            ),
            scaffoldBackgroundColor: AppTheme.background,
            appBarTheme: AppBarTheme(
              backgroundColor: AppTheme.background,
              foregroundColor: AppTheme.textDark,
              elevation: 0,
              centerTitle: false,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: AppTheme.surface,
              headerBackgroundColor: AppTheme.surfaceAlt,
              headerForegroundColor: AppTheme.textDark,
              dayForegroundColor: WidgetStateProperty.all(AppTheme.textDark),
              todayForegroundColor: WidgetStateProperty.all(AppTheme.success),
              todayBorder: BorderSide(color: AppTheme.success),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            useMaterial3: true,
          ),
          home: const LoginPage(),
        );
      },
    );
  }
}
