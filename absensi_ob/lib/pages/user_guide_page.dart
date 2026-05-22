import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class UserGuidePage extends StatelessWidget {
  const UserGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textDark),
        title: Text(
          'Panduan Pengguna',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const _HeaderCard(),
          const SizedBox(height: 16),
          _GuideSection(
            title: 'Mulai Menggunakan Aplikasi',
            items: const [
              _GuideStep(
                icon: Icons.login_rounded,
                title: 'Login akun karyawan',
                description:
                    'Masukkan username dan password yang sudah terdaftar. Jika belum memiliki akun, lakukan registrasi terlebih dahulu.',
              ),
              _GuideStep(
                icon: Icons.face_retouching_natural_rounded,
                title: 'Registrasi wajah',
                description:
                    'Ikuti instruksi foto wajah sampai selesai. Data wajah dipakai untuk verifikasi saat absensi.',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _GuideSection(
            title: 'Absensi Harian',
            items: const [
              _GuideStep(
                icon: Icons.fingerprint_rounded,
                title: 'Absensi masuk',
                description:
                    'Buka Home, tekan tombol absensi masuk, lalu lakukan scan wajah dan izinkan akses lokasi.',
              ),
              _GuideStep(
                icon: Icons.logout_rounded,
                title: 'Absensi pulang',
                description:
                    'Setelah pekerjaan selesai, lakukan absensi pulang dari Home dengan proses verifikasi yang sama.',
              ),
              _GuideStep(
                icon: Icons.history_rounded,
                title: 'Cek riwayat',
                description:
                    'Buka menu Attendance untuk melihat catatan absensi yang sudah tersimpan di perangkat.',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _GuideSection(
            title: 'Pengajuan Karyawan',
            items: const [
              _GuideStep(
                icon: Icons.payments_rounded,
                title: 'Pengajuan kasbon',
                description:
                    'Pilih Pengajuan Kasbon, isi nominal dan keterangan, lalu kirim agar admin dapat meninjau pengajuan.',
              ),
              _GuideStep(
                icon: Icons.event_available_rounded,
                title: 'Pengajuan cuti',
                description:
                    'Pilih jenis cuti, tanggal mulai, tanggal selesai, alasan, dan kontak yang dapat dihubungi.',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _GuideSection(
            title: 'Akun dan Bantuan',
            items: const [
              _GuideStep(
                icon: Icons.manage_accounts_rounded,
                title: 'Profile settings',
                description:
                    'Gunakan menu Profile Settings untuk mengubah nama, nomor HP, atau password akun.',
              ),
              _GuideStep(
                icon: Icons.support_agent_rounded,
                title: 'Hubungi admin',
                description:
                    'Jika ada data absensi, akun, atau pengajuan yang tidak sesuai, hubungi admin perusahaan untuk pengecekan.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Row(
        children: [
          _IconBadge(icon: Icons.menu_book_rounded, color: AppTheme.armyGreen),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panduan Aplikasi Absensi',
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Ringkasan langkah penggunaan fitur utama untuk karyawan.',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    height: 1.4,
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

class _GuideSection extends StatelessWidget {
  final String title;
  final List<_GuideStep> items;

  const _GuideSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
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
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _GuideStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBadge(
            icon: icon,
            color: AppTheme.armyGreen,
            size: 34,
            iconSize: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    height: 1.4,
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

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  const _IconBadge({
    required this.icon,
    required this.color,
    this.size = 52,
    this.iconSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size > 40 ? 16 : 12),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}
