import 'package:flutter/material.dart';
import 'dart:async';
import 'main_shell.dart';
import '../services/api_service.dart';
import '../core/app_theme.dart';
import '../widgets/app_form_field.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/design_system/soft_components.dart';
import 'register_page.dart';
import '../services/permission_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(_fadeAnimation);
    _fadeController.forward();

    // Request permissions safely after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionService.requestAllPermissions();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
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
              builder: (_) => MainShell(
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
    } catch (e) {
      setState(() => _isLoading = false);
      showErrorSnackbar(context, 'Gagal terhubung ke server: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    _buildLogo(),
                    const SizedBox(height: 28),
                    _buildTitle(),
                    const SizedBox(height: 32),
                    _buildFormCard(),
                    const SizedBox(height: 28),
                    _buildLoginButton(),
                    const SizedBox(height: 24),
                    _buildRegisterLink(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: SizedBox(
        width: 170,
        height: 170,
        child: Image.asset(
          'assets/logo.png',
          fit: BoxFit.contain,
          errorBuilder: (_, e, st) => Icon(
            Icons.face_retouching_natural_rounded,
            color: AppTheme.armyGreenDark,
            size: 44,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'Selamat Datang',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Absensi Karyawan Office Boy\nMarkas Besar Angkatan Darat',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: AppTheme.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: 44,
          height: 3.5,
          decoration: BoxDecoration(
            color: AppTheme.armyGreenDark,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: AppTheme.clayDecoration(radius: AppTheme.radiusXl),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          AppFormField(
            controller: _usernameController,
            label: 'Username',
            hint: 'Masukkan username',
            icon: Icons.alternate_email_rounded,
            labelFontSize: 18,
            validator: (v) =>
                v == null || v.isEmpty ? 'Username tidak boleh kosong' : null,
          ),
          const SizedBox(height: 18),
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
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Password tidak boleh kosong' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return ClayButton(
      label: 'Masuk',
      icon: Icons.login_rounded,
      isLoading: _isLoading,
      onPressed: _isLoading ? null : _login,
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Belum punya akun? ',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 15),
        ),
        TextButton(
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RegisterPage()),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Daftar',
            style: TextStyle(
              color: AppTheme.armyGreen,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
