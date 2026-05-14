import 'dart:io';
import 'dart:async';
import 'package:absensi_ob/pages/login_page.dart';
import 'package:absensi_ob/pages/history_page.dart';
import 'package:absensi_ob/pages/messages_page.dart';
import 'package:absensi_ob/pages/more_page.dart';
import 'package:absensi_ob/services/session_manager.dart';
import 'package:absensi_ob/services/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'face_scan_page.dart';
import '../controllers/attendance_controller.dart';
import '../core/app_constants.dart';
import '../core/app_theme.dart';

class HomePage extends StatefulWidget {
  final String name;
  final String phoneNumber;
  final String? profilePhotoUrl;

  const HomePage({
    super.key,
    required this.name,
    required this.phoneNumber,
    this.profilePhotoUrl,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final AttendanceController _controller;
  late Timer _clockTimer;
  late String _employeeName;
  late String _employeePhoneNumber;
  String? _employeeProfilePhotoUrl;
  String _currentTime = '';
  String _currentDate = '';
  int _currentNavIndex = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;

  // ── Dark theme colors matching screenshot ──
  static const Color _bgDark = Color(0xFF0E2140);
  static const Color _cardDark = Color(0xFF1A3A5C);
  static const Color _btnGreen = Color(0xFF2ECC8A);
  static const Color _btnGreenDark = Color(0xFF1FAF72);
  static const Color _btnRed = Color(0xFFE53935);
  static const Color _textWhite = Colors.white;
  static const Color _textMuted = Color(0xFF7BAFD4);
  static const Color _dividerColor = Color(0xFF1E4060);
  static const Color _ringColor = Color(0xFF2ECC8A);

  @override
  void initState() {
    super.initState();
    _employeeName = widget.name;
    _employeePhoneNumber = widget.phoneNumber;
    _employeeProfilePhotoUrl = widget.profilePhotoUrl;
    _controller = AttendanceController(
      name: widget.name,
      phoneNumber: widget.phoneNumber,
    );
    _controller.addListener(() => setState(() {}));

    _controller.init().then((needsRegistration) {
      if (needsRegistration && mounted) {
        _showRegisterFaceDialog();
      }
    });

    _updateTime();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTime(),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _ringAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeInOut),
    );
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm').format(now);
      _currentDate = DateFormat('EEEE, dd MMM yyyy').format(now);
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _pulseController.dispose();
    _ringController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  //  EVENT HANDLERS — hanya panggil controller, lalu tampilkan hasil
  // ══════════════════════════════════════════════════════════════

  Future<void> _onClockIn() async {
    final path = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const FaceScanPage()),
    );
    if (path == null || !mounted) return;

    final result = await _controller.clockIn(File(path));
    if (mounted) _showResultDialog(result.message, result.success);
  }

  Future<void> _onClockOut() async {
    final path = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const FaceScanPage()),
    );
    if (path == null || !mounted) return;

    final result = await _controller.clockOut(File(path));
    if (mounted) _showResultDialog(result.message, result.success);
  }

  Future<void> _onRegisterFace() async {
    final List<File> photos = [];
    final instructions = AppConstants.faceRegisterInstructions;

    for (int i = 0; i < 3; i++) {
      if (!mounted) return;

      final path = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => FaceScanPage(instruction: instructions[i]),
        ),
      );

      if (path == null) {
        if (mounted) _showResultDialog('Registrasi dibatalkan', false);
        return;
      }

      photos.add(File(path));

      if (i < 2 && mounted) {
        await _showPhotoProgressDialog(i + 1);
      }
    }

    if (!mounted) return;
    final result = await _controller.registerFace(photos);

    if (mounted) {
      _showResultDialog(result.message, result.success);
      if (!result.success) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) _showRegisterFaceDialog();
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  DIALOGS — hanya tampilan, tidak ada logic bisnis
  // ══════════════════════════════════════════════════════════════

  void _showRegisterFaceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Registrasi Wajah',
          style: TextStyle(color: _textWhite),
        ),
        content: const Text(
          'Wajah kamu belum terdaftar. Silakan registrasi wajah terlebih dahulu untuk bisa absen.',
          style: TextStyle(color: _textMuted),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _onRegisterFace();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _btnGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Registrasi Sekarang',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPhotoProgressDialog(int photoNumber) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: _cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF22C55E),
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                '✅ Foto $photoNumber/3 berhasil!\nSiap untuk foto berikutnya.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: _textWhite),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _btnGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Lanjut Foto Berikutnya',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResultDialog(String message, bool success) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFEF4444),
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: _textWhite),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: success
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildMainScaffold(),
        if (_controller.isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Dialog(
                backgroundColor: _cardDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: _btnGreen),
                      const SizedBox(height: 40),
                      Text(
                        _controller.loadingMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _textWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMainScaffold() {
    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(),
              _buildDateBadge(),
              _buildBigClock(),
              _buildClockButton(),
              const SizedBox(height: 20),
              _buildLocationBadge(),
              const SizedBox(height: 20),
              _buildStatusCard(),
              const SizedBox(height: 10), // space for bottom nav
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SELAMAT PAGI',
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _employeeName,
                style: const TextStyle(
                  color: _textWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          _buildAppBarIcon(Icons.logout_rounded, () async {
            await TokenStorage.clearToken();
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAppBarIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: _textMuted, size: 20),
      ),
    );
  }

  // ─── Date Badge ───────────────────────────────────────────

  Widget _buildDateBadge() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: _btnGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _currentDate,
              style: const TextStyle(
                color: _textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Big Clock Display ────────────────────────────────────

  Widget _buildBigClock() {
    // Split time into hours and minutes for the stacked display in screenshot
    final parts = _currentTime.split(':');
    final hours = parts.isNotEmpty ? parts[0] : '--';
    final minutes = parts.length > 1 ? parts[1] : '--';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$hours:',
            style: const TextStyle(
              color: _textWhite,
              fontSize: 72,
              fontWeight: FontWeight.w900,
              height: 0.95,
              letterSpacing: -2,
            ),
          ),
          Text(
            minutes,
            style: const TextStyle(
              color: _textWhite,
              fontSize: 72,
              fontWeight: FontWeight.w900,
              height: 0.95,
              letterSpacing: -2,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Clock In / Out Button (Big Circle with Ring) ─────────

  Widget _buildClockButton() {
    final bool hasClockedIn = _controller.isClockedIn;
    final bool hasClockedOut = _controller.clockOutTime != '--:--';
    final bool showClockOut = hasClockedIn && !hasClockedOut;
    final bool allDone = hasClockedIn && hasClockedOut;

    final String label = allDone
        ? 'SELESAI'
        : showClockOut
        ? 'CLOCK OUT'
        : 'CLOCK IN';

    final VoidCallback? onTap = allDone
        ? null
        : showClockOut
        ? _onClockOut
        : _onClockIn;

    final Color btnColor = allDone
        ? const Color(0xFF4A5568)
        : showClockOut
        ? _btnRed
        : _btnGreen;

    final Color btnColorDark = allDone
        ? const Color(0xFF3A4555)
        : showClockOut
        ? const Color(0xFF6B2A2A)
        : _btnGreenDark;

    final IconData btnIcon = allDone
        ? Icons.check_circle_outline
        : showClockOut
        ? Icons.logout_rounded
        : Icons.crop_square_rounded; // matches square icon in screenshot

    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = allDone ? 1.0 : _pulseAnimation.value;
          return Transform.scale(
            scale: scale,
            child: GestureDetector(
              onTap: onTap,
              child: AnimatedBuilder(
                animation: _ringAnimation,
                builder: (context, child) {
                  return SizedBox(
                    width: 330,
                    height: 330,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outermost dashed ring
                        Container(
                          width: 230,
                          height: 230,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _ringColor.withValues(
                                alpha: _ringAnimation.value * 0.3,
                              ),
                              width: 1,
                            ),
                          ),
                        ),
                        // Middle ring
                        Container(
                          width: 176,
                          height: 176,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _ringColor.withValues(
                                alpha: _ringAnimation.value * 0.5,
                              ),
                              width: 1.5,
                            ),
                          ),
                        ),
                        // Inner ring (subtle glow arc)
                        Container(
                          width: 158,
                          height: 158,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _ringColor.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                        ),
                        // Main button circle
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: Alignment.topLeft,
                              radius: 1.2,
                              colors: [btnColor, btnColorDark],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: btnColor.withValues(alpha: 0.35),
                                blurRadius: 28,
                                spreadRadius: 2,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(btnIcon, color: Colors.white, size: 36),
                              const SizedBox(height: 8),
                              Text(
                                label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Location Badge ───────────────────────────────────────

  Widget _buildLocationBadge() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.location_on, color: _textMuted, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _controller.alamatMasuk ?? 'Menunggu lokasi...',
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Status Card (dark) ───────────────────────────────────

  Widget _buildStatusCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatusItem(
              icon: Icons.login_rounded,
              iconBgColor: _btnGreenDark.withValues(alpha: 0.5),
              iconColor: _btnGreen,
              time: _controller.clockInTime,
              label: 'Clock In',
              accentColor: const Color(0xFF22C55E),
            ),
            _buildStatusDivider(),
            _buildStatusItem(
              icon: Icons.logout_rounded,
              iconBgColor: const Color(0xFF5A2020),
              iconColor: const Color(0xFFEF4444),
              time: _controller.clockOutTime,
              label: 'Clock Out',
              accentColor: const Color(0xFFEF4444),
            ),
            _buildStatusDivider(),
            _buildStatusItem(
              icon: Icons.timer_outlined,
              iconBgColor: const Color(0xFF1A3A50),
              iconColor: const Color(0xFF60A5FA),
              time: _calculateDuration(),
              label: 'Durasi',
              accentColor: const Color(0xFF60A5FA),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String time,
    required String label,
    required Color accentColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 10),
        Text(
          time,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: accentColor,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDivider() {
    return Container(width: 1, height: 56, color: _dividerColor);
  }

  String _calculateDuration() {
    if (_controller.clockInTime == '--:--') return '--:--';
    if (_controller.clockOutTime == '--:--') {
      if (_controller.timestampMasuk != null) {
        final diff = DateTime.now().difference(_controller.timestampMasuk!);
        final h = diff.inHours.toString().padLeft(2, '0');
        final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
        return '$h:$m';
      }
      return '--:--';
    }
    if (_controller.timestampMasuk != null &&
        _controller.timestampPulang != null) {
      final diff = _controller.timestampPulang!.difference(
        _controller.timestampMasuk!,
      );
      final h = diff.inHours.toString().padLeft(2, '0');
      final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '--:--';
  }

  // ─── Bottom Navigation Bar ────────────────────────────────

  Widget _buildBottomNav() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F1C28),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BottomNavigationBar(
              currentIndex: _currentNavIndex,
              onTap: (index) async {
                if (index == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoryPage(
                        records: SessionManager.getRecords(widget.name),
                      ),
                    ),
                  );
                } else if (index == 2) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MessagesPage()),
                  );

                  if (!mounted) return;
                  setState(() => _currentNavIndex = 0);
                } else if (index == 3) {
                  final updatedEmployee =
                      await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MorePage(
                            name: _employeeName,
                            phoneNumber: _employeePhoneNumber,
                            profilePhotoUrl: _employeeProfilePhotoUrl,
                            onRegisterFace: _onRegisterFace,
                            records: SessionManager.getRecords(widget.name),
                          ),
                        ),
                      );

                  if (!mounted) return;

                  if (updatedEmployee != null) {
                    _applyUpdatedEmployee(updatedEmployee);
                  }

                  setState(() => _currentNavIndex = 0);
                } else {
                  setState(() => _currentNavIndex = index);
                }
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: const Color(0xFF0F1C28),
              selectedItemColor: Colors.white,
              unselectedItemColor: _textMuted,
              selectedFontSize: 12,
              unselectedFontSize: 11,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_rounded),
                  label: 'Absensi',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications_outlined),
                  label: 'Notifikasi',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.more_horiz),
                  label: 'More',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _applyUpdatedEmployee(Map<String, dynamic> employee) {
    setState(() {
      _employeeName = employee['name'] as String? ?? _employeeName;
      _employeePhoneNumber =
          employee['phone'] as String? ?? _employeePhoneNumber;
      _employeeProfilePhotoUrl =
          employee['profile_photo_url'] as String? ?? _employeeProfilePhotoUrl;
    });
  }
}
