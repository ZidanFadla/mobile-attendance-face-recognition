import 'package:absensi_ob/pages/login_page.dart';
import 'package:absensi_ob/services/permission_service.dart';
import 'package:absensi_ob/core/app_theme.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await PermissionService.requestAllPermissions();
  } catch (e) {
    debugPrint('Permission initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absensi OB',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.armyGreen,
          brightness: Brightness.dark,
          surface: AppTheme.surface,
        ),
        scaffoldBackgroundColor: AppTheme.background,
        appBarTheme: const AppBarTheme(
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
  }
}
