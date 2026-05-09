import 'package:absensi_ob/models/attendance_record.dart';
import 'package:absensi_ob/pages/cash_advance_request_page.dart';
import 'package:absensi_ob/pages/leave_request_page.dart';
import 'package:absensi_ob/pages/login_page.dart';
import 'package:absensi_ob/pages/profile_settings_page.dart';
import 'package:absensi_ob/pages/user_guide_page.dart';
import 'package:absensi_ob/services/token_storage.dart';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class MorePage extends StatefulWidget {
  final String name;
  final String phoneNumber;
  final String? profilePhotoUrl;
  final VoidCallback onRegisterFace;
  final List<AttendanceRecord> records;

  const MorePage({
    super.key,
    required this.name,
    required this.phoneNumber,
    this.profilePhotoUrl,
    required this.onRegisterFace,
    required this.records,
  });

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  late String _name;
  late String _phoneNumber;
  String? _profilePhotoUrl;
  Map<String, dynamic>? _updatedEmployee;

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _phoneNumber = widget.phoneNumber;
    _profilePhotoUrl = widget.profilePhotoUrl;
  }

  void _applyUpdatedEmployee(Map<String, dynamic> employee) {
    setState(() {
      _updatedEmployee = employee;
      _name = employee['name'] as String? ?? _name;
      _phoneNumber = employee['phone'] as String? ?? _phoneNumber;
      _profilePhotoUrl =
          employee['profile_photo_url'] as String? ?? _profilePhotoUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          elevation: 0,
          title: const Text(
            'More',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          iconTheme: const IconThemeData(color: AppColors.textDark),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _ProfileHeader(
              name: _name,
              phoneNumber: _phoneNumber,
              profilePhotoUrl: _profilePhotoUrl,
            ),
            const SizedBox(height: 18),
            _SectionTitle('Akun & Presensi'),
            _MenuTile(
              icon: Icons.manage_accounts_rounded,
              color: AppColors.accent,
              title: 'Profile Settings',
              subtitle: 'Ubah nama, nomor HP, dan password akun.',
              onTap: () async {
                final employee = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileSettingsPage(
                      name: _name,
                      phoneNumber: _phoneNumber,
                      profilePhotoUrl: _profilePhotoUrl,
                    ),
                  ),
                );
                if (employee != null && mounted) {
                  _applyUpdatedEmployee(employee);
                  Navigator.pop(context, employee);
                }
              },
            ),
            _MenuTile(
              icon: Icons.face_retouching_natural_rounded,
              color: AppColors.primary,
              title: 'Registrasi ulang wajah',
              subtitle: 'Perbarui data wajah jika verifikasi sering gagal.',
              onTap: () {
                Navigator.pop(context, _updatedEmployee);
                widget.onRegisterFace();
              },
            ),
            _MenuTile(
              icon: Icons.payments_rounded,
              color: AppColors.success,
              title: 'Pengajuan Kasbon',
              subtitle: 'Ajukan Kasbon kepada perusahaan melalui aplikasi.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CashAdvanceRequestPage(),
                  ),
                );
              },
            ),
            _MenuTile(
              icon: Icons.event_available_rounded,
              color: const Color(0xFFF59E0B),
              title: 'Pengajuan Cuti',
              subtitle: 'Pengajuan Cuti Ke Perusahaan Melalui Aplikasi.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LeaveRequestPage()),
                );
              },
            ),
            const SizedBox(height: 18),
            _SectionTitle('Bantuan'),
            _MenuTile(
              icon: Icons.menu_book_rounded,
              color: const Color(0xFF0EA5E9),
              title: 'Panduan Pengguna Aplikasi',
              subtitle: 'Lihat cara menggunakan fitur utama aplikasi.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserGuidePage()),
                );
              },
            ),
            const SizedBox(height: 18),
            _MenuTile(
              icon: Icons.logout_rounded,
              color: AppColors.error,
              title: 'Logout',
              subtitle: 'Keluar dari akun karyawan di perangkat ini.',
              onTap: () async {
                await TokenStorage.clearToken();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false,
                );
              },
            ),
          ],
        ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String phoneNumber;
  final String? profilePhotoUrl;

  const _ProfileHeader({
    required this.name,
    required this.phoneNumber,
    required this.profilePhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final photoUrl = profilePhotoUrl;
    final imageProvider = photoUrl != null && photoUrl.isNotEmpty
        ? NetworkImage(photoUrl)
        : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF8B7CF6), Color(0xFF4F6AF0)],
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageProvider != null
                ? Image(image: imageProvider, fit: BoxFit.cover)
                : Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
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
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phoneNumber,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
