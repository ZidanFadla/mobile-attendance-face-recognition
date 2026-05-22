import 'package:flutter/material.dart';
import 'cash_advance_request_page.dart';
import 'leave_request_page.dart';
import 'login_page.dart';
import 'profile_settings_page.dart';
import 'request_history_page.dart';
import 'user_guide_page.dart';
import '../core/app_theme.dart';
import '../services/session_manager.dart';
import '../services/token_storage.dart';

/// More tab — stateless display. Data flows from [MainShell].
class MorePage extends StatelessWidget {
  final String name;
  final String phoneNumber;
  final String? profilePhotoUrl;
  final VoidCallback onRegisterFace;
  final ValueChanged<Map<String, dynamic>> onEmployeeUpdated;

  const MorePage({
    super.key,
    required this.name,
    required this.phoneNumber,
    this.profilePhotoUrl,
    required this.onRegisterFace,
    required this.onEmployeeUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'More',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _ProfileHeader(
            name: name,
            phoneNumber: phoneNumber,
            profilePhotoUrl: profilePhotoUrl,
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Akun & Presensi'),
          _AnimatedMenuTile(
            index: 0,
            icon: Icons.manage_accounts_rounded,
            color: AppTheme.accentOrange,
            title: 'Profile Settings',
            subtitle: 'Ubah nama, nomor HP, dan password akun.',
            onTap: () async {
              final employee = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileSettingsPage(
                    name: name,
                    phoneNumber: phoneNumber,
                    profilePhotoUrl: profilePhotoUrl,
                  ),
                ),
              );
              if (employee != null) onEmployeeUpdated(employee);
            },
          ),
          _AnimatedMenuTile(
            index: 1,
            icon: Icons.face_retouching_natural_rounded,
            color: AppTheme.armyGreen,
            title: 'Registrasi ulang wajah',
            subtitle: 'Perbarui data wajah jika verifikasi sering gagal.',
            onTap: onRegisterFace,
          ),
          _AnimatedMenuTile(
            index: 2,
            icon: Icons.payments_rounded,
            color: AppTheme.success,
            title: 'Pengajuan Kasbon',
            subtitle: 'Ajukan Kasbon kepada perusahaan melalui aplikasi.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CashAdvanceRequestPage(),
              ),
            ),
          ),
          _AnimatedMenuTile(
            index: 3,
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFF0EA5E9),
            title: 'Riwayat Kasbon',
            subtitle: 'Lihat status pengajuan dan total kasbon yang disetujui.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RequestHistoryPage(
                  type: RequestHistoryType.cashAdvance,
                ),
              ),
            ),
          ),
          _AnimatedMenuTile(
            index: 4,
            icon: Icons.event_available_rounded,
            color: const Color(0xFFF59E0B),
            title: 'Pengajuan Cuti',
            subtitle: 'Pengajuan Cuti Ke Perusahaan Melalui Aplikasi.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeaveRequestPage()),
            ),
          ),
          _AnimatedMenuTile(
            index: 5,
            icon: Icons.event_note_rounded,
            color: const Color(0xFF8B5CF6),
            title: 'Riwayat Cuti',
            subtitle:
                'Pantau pengajuan cuti yang menunggu, disetujui, atau ditolak.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const RequestHistoryPage(type: RequestHistoryType.leave),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Tampilan'),
          const _ThemeToggleCard(),
          const SizedBox(height: 20),
          const _SectionTitle('Bantuan'),
          _AnimatedMenuTile(
            index: 6,
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF0EA5E9),
            title: 'Panduan Pengguna Aplikasi',
            subtitle: 'Lihat cara menggunakan fitur utama aplikasi.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserGuidePage()),
            ),
          ),
          const SizedBox(height: 20),
          _AnimatedMenuTile(
            index: 7,
            icon: Icons.logout_rounded,
            color: AppTheme.error,
            title: 'Logout',
            subtitle: 'Keluar dari akun karyawan di perangkat ini.',
            onTap: () async {
              await TokenStorage.clearToken();
              SessionManager.clear();
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

// ── Reusable Widgets ─────────────────────────────────────────

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

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: AppTheme.gradientArmyGreen),
            ),
            clipBehavior: Clip.antiAlias,
            child: profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty
                ? Image.network(profilePhotoUrl!, fit: BoxFit.cover)
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
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phoneNumber,
                  style: TextStyle(
                    color: AppTheme.textMuted,
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
        style: TextStyle(
          color: AppTheme.textDark,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _AnimatedMenuTile extends StatefulWidget {
  final int index;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AnimatedMenuTile({
    required this.index,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_AnimatedMenuTile> createState() => _AnimatedMenuTileState();
}

class _AnimatedMenuTileState extends State<_AnimatedMenuTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (widget.index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              title: Text(
                widget.title,
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  widget.subtitle,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeToggleCard extends StatelessWidget {
  const _ThemeToggleCard();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppTheme.isDarkModeNotifier,
      builder: (context, isDark, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border),
            boxShadow: [AppTheme.cardShadow],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark 
                            ? const Color(0xFF1E3A5F) 
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: isDark ? const Color(0xFFFFA726) : const Color(0xFF0F172A),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mode Gelap',
                            style: TextStyle(
                              color: AppTheme.textDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isDark ? 'Kurangi ketegangan mata di malam hari.' : 'Tampilan bersih untuk siang hari.',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isDark,
                      activeThumbColor: AppTheme.btnGreen,
                      onChanged: (val) {
                        AppTheme.isDarkModeNotifier.value = val;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
