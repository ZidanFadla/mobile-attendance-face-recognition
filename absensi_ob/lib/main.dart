import 'package:absensi_ob/core/app_theme.dart';
import 'package:absensi_ob/pages/login_page.dart';
import 'package:absensi_ob/pages/main_shell.dart';
import 'package:absensi_ob/pages/splash_page.dart';
import 'package:absensi_ob/services/api_service.dart';
import 'package:absensi_ob/services/face_recognition_service.dart';
import 'package:absensi_ob/services/session_manager.dart';
import 'package:absensi_ob/services/token_storage.dart';
import 'package:flutter/material.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppTheme.init();
  await PushNotificationService.ensureInitialized();
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
          home: const SplashPage(nextPage: AuthGate()),
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _openInitialPage();
  }

  Future<void> _openInitialPage() async {
    Widget nextPage = const LoginPage();

    try {
      final token = await TokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        final employee = await ApiService.fetchCurrentEmployee();
        final id = employee['id'];
        final name = employee['name'];
        final phone = employee['phone'];

        if (id != null && name != null && phone != null) {
          SessionManager.clear();
          FaceRecognitionService.setCacheOwner(id.toString());
          nextPage = MainShell(
            name: name.toString(),
            phoneNumber: phone.toString(),
            profilePhotoUrl: employee['profile_photo_url'] as String?,
          );
        }
      }
    } catch (_) {
      await TokenStorage.clearToken();
      SessionManager.clear();
    }

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => nextPage));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.clayPrimary),
      ),
    );
  }
}
