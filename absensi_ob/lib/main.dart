import 'package:absensi_ob/pages/login_page.dart';
import 'package:absensi_ob/services/permission_service.dart';
import 'package:flutter/material.dart';

void main() async {
  // ✅ Wajib dipanggil sebelum runApp() jika ada operasi async di main
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Request permissions sebelum app dimulai
  try {
    await PermissionService.requestAllPermissions();
  } catch (e) {
    print('Permission initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // ✅ Gaya super.key modern, bukan Key? key

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absensi OB',
      debugShowCheckedModeBanner: false,
      // ✅ colorScheme + useMaterial3 menggantikan primarySwatch yang deprecated
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
