import 'package:absensi_ob/models/attendance_record.dart';
import 'package:absensi_ob/pages/history_page.dart';
import 'package:absensi_ob/pages/login_page.dart';
import 'package:absensi_ob/pages/messages_page.dart';
import 'package:absensi_ob/services/token_storage.dart';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class MorePage extends StatelessWidget {
  final String name;
  final String phoneNumber;
  final VoidCallback onRegisterFace;
  final List<AttendanceRecord> records;

  const MorePage({
    super.key,
    required this.name,
    required this.phoneNumber,
    required this.onRegisterFace,
    required this.records,
  });

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
          _ProfileHeader(name: name, phoneNumber: phoneNumber),
          const SizedBox(height: 18),
          _SectionTitle('Akun & Presensi'),
          _MenuTile(
            icon: Icons.face_retouching_natural_rounded,
            color: AppColors.primary,
            title: 'Registrasi ulang wajah',
            subtitle: 'Perbarui data wajah jika verifikasi sering gagal.',
            onTap: () {
              Navigator.pop(context);
              onRegisterFace();
            },
          ),
          _MenuTile(
            icon: Icons.history_rounded,
            color: AppColors.success,
            title: 'Riwayat presensi',
            subtitle: 'Lihat clock in dan clock out yang tersimpan.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HistoryPage(records: records)),
              );
            },
          ),
          _MenuTile(
            icon: Icons.notifications_rounded,
            color: const Color(0xFFF59E0B),
            title: 'Pesan admin',
            subtitle: 'Buka pengumuman dan instruksi dari web admin.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MessagesPage()),
              );
            },
          ),
          const SizedBox(height: 18),
          _SectionTitle('Saran isi halaman More'),
          const _SuggestionBox(),
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

  const _ProfileHeader({required this.name, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

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
            child: Center(
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

class _SuggestionBox extends StatelessWidget {
  const _SuggestionBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: const Text(
        'Cocoknya More diisi profil karyawan, registrasi ulang wajah, riwayat presensi, pesan admin, logout, lalu nanti bisa ditambah pengajuan izin, ubah password, bantuan, dan kebijakan kantor.',
        style: TextStyle(color: AppColors.textDark, fontSize: 13, height: 1.45),
      ),
    );
  }
}
