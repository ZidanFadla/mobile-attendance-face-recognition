import 'package:flutter/material.dart';
import 'dart:async';
import 'home_page.dart';
import '../services/api_service.dart';
import '../core/app_theme.dart';
import '../widgets/app_form_field.dart';
import '../widgets/app_snackbar.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (data['success'] == true) {
        final employee = data['employee'];
        if (employee != null &&
            employee['name'] != null &&
            employee['phone'] != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(
                name: employee['name'],
                phoneNumber: employee['phone'],
                profilePhotoUrl: employee['profile_photo_url'] as String?,
              ),
            ),
          );
        } else {
          showErrorSnackbar(context, 'Data karyawan tidak lengkap');
        }
      } else {
        showErrorSnackbar(context, data['message'] ?? 'Login gagal');
      }
    } on TimeoutException {
      setState(() => _isLoading = false);
      showErrorSnackbar(
        context,
        'Server tidak merespons. Pastikan server berjalan.',
      );
    } on FormatException {
      setState(() => _isLoading = false);
      showErrorSnackbar(
        context,
        'Response server tidak valid. Periksa konfigurasi API.',
      );
    } catch (e) {
      setState(() => _isLoading = false);
      showErrorSnackbar(context, 'Gagal terhubung ke server: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),

                    // Logo
                    Center(
                      child: Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppTheme.gradientArmyGreen,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.armyGreen.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.fingerprint,
                                  color: Colors.white,
                                  size: 40,
                                ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Title
                    const Text(
                      'Selamat Datang',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Absensi Karyawan Office Boy\nMarkas Besar Angkatan Darat',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Divider dekoratif
                    Center(
                      child: Container(
                        width: 40,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppTheme.gradientArmyGreen,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Form Card
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [AppTheme.cardShadow],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          AppFormField(
                            controller: _usernameController,
                            label: 'Username',
                            hint: 'Masukkan username',
                            icon: Icons.alternate_email_rounded,
                            labelFontSize: 18,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Username tidak boleh kosong'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          AppFormField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'Masukkan password',
                            icon: Icons.lock_outline_rounded,
                            labelFontSize: 18,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppTheme.textMuted,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Password tidak boleh kosong'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: _isLoading
                            ? null
                            : const LinearGradient(
                                colors: AppTheme.gradientArmyGreen,
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                        color: _isLoading ? AppTheme.border : null,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: _isLoading ? [] : [AppTheme.buttonShadow],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: AppTheme.armyGreen,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Masuk',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Belum punya akun? ',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterPage(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 2,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppTheme.armyGreen,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            child: const Text(
                              'Daftar',
                              style: TextStyle(
                                color: AppTheme.armyGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
