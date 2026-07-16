import 'package:absensi_ob/core/app_theme.dart';
import 'package:absensi_ob/pages/login_page.dart';
import 'package:absensi_ob/pages/splash_page.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppTheme.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppTheme.isDarkModeNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'Absensi OB',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: const SplashPage(nextPage: LoginPage()),
        );
      },
    );
  }
}
