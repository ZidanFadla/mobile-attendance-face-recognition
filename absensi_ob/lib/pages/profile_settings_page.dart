import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/app_form_field.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/request_forms/request_form_widgets.dart';

class ProfileSettingsPage extends StatefulWidget {
  final String name;
  final String phoneNumber;
  final String? profilePhotoUrl;

  const ProfileSettingsPage({
    super.key,
    required this.name,
    required this.phoneNumber,
    this.profilePhotoUrl,
  });

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _imagePicker = ImagePicker();

  File? _selectedProfilePhoto;
  late String? _profilePhotoUrl;
  bool _isSavingProfile = false;
  bool _isSavingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _phoneController = TextEditingController(text: widget.phoneNumber);
    _profilePhotoUrl = widget.profilePhotoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _isSavingProfile = true);

    try {
      var data = await ApiService.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (data['success'] == true && _selectedProfilePhoto != null) {
        data = await ApiService.uploadProfilePhoto(_selectedProfilePhoto!);
      }

      if (!mounted) return;
      setState(() => _isSavingProfile = false);

      if (data['success'] == true) {
        final employee = data['employee'];
        if (employee is Map) {
          setState(() {
            _profilePhotoUrl = employee['profile_photo_url'] as String?;
            _selectedProfilePhoto = null;
          });
          _showSuccess(data['message'] ?? 'Profile berhasil diperbarui.');
          Navigator.pop(context, Map<String, dynamic>.from(employee));
          return;
        }
        _showSuccess(data['message'] ?? 'Profile berhasil diperbarui.');
      } else {
        showErrorSnackbar(
          context,
          data['message'] ?? 'Gagal memperbarui profile.',
        );
      }
    } on TimeoutException {
      _handleError('Server tidak merespons. Pastikan server berjalan.');
    } catch (e) {
      _handleError('Gagal memperbarui profile: ${e.toString()}');
    }
  }

  Future<void> _pickProfilePhoto(ImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 900,
    );
    if (image == null) return;

    setState(() => _selectedProfilePhoto = File(image.path));
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                RequestSourceTile(
                  icon: Icons.photo_camera_rounded,
                  title: 'Ambil Foto',
                  onTap: () {
                    Navigator.pop(context);
                    _pickProfilePhoto(ImageSource.camera);
                  },
                ),
                RequestSourceTile(
                  icon: Icons.photo_library_rounded,
                  title: 'Pilih dari Galeri',
                  onTap: () {
                    Navigator.pop(context);
                    _pickProfilePhoto(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _isSavingPassword = true);

    try {
      final data = await ApiService.changePassword(
        currentPassword: _currentPasswordController.text,
        password: _newPasswordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (!mounted) return;
      setState(() => _isSavingPassword = false);

      if (data['success'] == true) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _showSuccess(data['message'] ?? 'Password berhasil diganti.');
      } else {
        showErrorSnackbar(
          context,
          data['message'] ?? 'Gagal mengganti password.',
        );
      }
    } on TimeoutException {
      _handleError('Server tidak merespons. Pastikan server berjalan.');
    } catch (e) {
      _handleError('Gagal mengganti password: ${e.toString()}');
    }
  }

  void _handleError(String message) {
    if (!mounted) return;
    setState(() {
      _isSavingProfile = false;
      _isSavingPassword = false;
    });
    showErrorSnackbar(context, message);
  }

  void _showSuccess(String message) {
    showSuccessSnackbar(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textDark),
        title: Text(
          'Profile Settings',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _ProfileSummary(
            name: _nameController.text,
            phoneNumber: _phoneController.text,
            profilePhoto: _selectedProfilePhoto,
            profilePhotoUrl: _profilePhotoUrl,
            onChangePhoto: _showPhotoSourceSheet,
          ),
          const SizedBox(height: 16),
          Form(
            key: _profileFormKey,
            child: _SectionCard(
              title: 'Informasi Profile',
              children: [
                AppFormField(
                  controller: _nameController,
                  label: 'Nama Lengkap',
                  hint: 'Masukkan nama lengkap',
                  icon: Icons.person_rounded,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nama wajib diisi'
                      : null,
                ),
                const SizedBox(height: 14),
                AppFormField(
                  controller: _phoneController,
                  label: 'Nomor HP',
                  hint: 'Masukkan nomor HP',
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nomor HP wajib diisi'
                      : null,
                ),
                const SizedBox(height: 18),
                _PrimaryButton(
                  label: 'Simpan Profile',
                  icon: Icons.save_rounded,
                  isLoading: _isSavingProfile,
                  onPressed: _saveProfile,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Form(
            key: _passwordFormKey,
            child: _SectionCard(
              title: 'Ganti Password',
              children: [
                AppFormField(
                  controller: _currentPasswordController,
                  label: 'Password Saat Ini',
                  hint: 'Masukkan password saat ini',
                  icon: Icons.lock_rounded,
                  obscureText: _obscureCurrentPassword,
                  suffixIcon: _PasswordToggle(
                    obscure: _obscureCurrentPassword,
                    onPressed: () => setState(
                      () => _obscureCurrentPassword = !_obscureCurrentPassword,
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Password saat ini wajib diisi'
                      : null,
                ),
                const SizedBox(height: 14),
                AppFormField(
                  controller: _newPasswordController,
                  label: 'Password Baru',
                  hint: 'Minimal 6 karakter',
                  icon: Icons.lock_reset_rounded,
                  obscureText: _obscureNewPassword,
                  suffixIcon: _PasswordToggle(
                    obscure: _obscureNewPassword,
                    onPressed: () => setState(
                      () => _obscureNewPassword = !_obscureNewPassword,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password baru wajib diisi';
                    }
                    if (value.length < 6) return 'Password minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AppFormField(
                  controller: _confirmPasswordController,
                  label: 'Konfirmasi Password Baru',
                  hint: 'Ulangi password baru',
                  icon: Icons.verified_user_rounded,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: _PasswordToggle(
                    obscure: _obscureConfirmPassword,
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi wajib diisi';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Konfirmasi password tidak sama';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _PrimaryButton(
                  label: 'Ganti Password',
                  icon: Icons.key_rounded,
                  isLoading: _isSavingPassword,
                  onPressed: _changePassword,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  final String name;
  final String phoneNumber;
  final File? profilePhoto;
  final String? profilePhotoUrl;
  final VoidCallback onChangePhoto;

  const _ProfileSummary({
    required this.name,
    required this.phoneNumber,
    required this.profilePhoto,
    required this.profilePhotoUrl,
    required this.onChangePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final photoUrl = profilePhotoUrl;
    final imageProvider = profilePhoto != null
        ? FileImage(profilePhoto!) as ImageProvider
        : photoUrl != null && photoUrl.isNotEmpty
        ? NetworkImage(photoUrl)
        : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppTheme.armyGreen,
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: InkWell(
                  onTap: onChangePhoto,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.armyGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.surface, width: 3),
                    ),
                    child: const Icon(
                      Icons.photo_camera_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phoneNumber,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _PasswordToggle extends StatelessWidget {
  final bool obscure;
  final VoidCallback onPressed;

  const _PasswordToggle({required this.obscure, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        color: AppTheme.textMuted,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, size: 19),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.armyGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.armyGreen.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
    );
  }
}
