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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Registrasi Wajah'),
        content: const Text(
          'Wajah kamu belum terdaftar. Silakan registrasi wajah terlebih dahulu untuk bisa absen.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _onRegisterFace();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
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
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
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
                style: const TextStyle(fontSize: 15),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF6C63FF)),
                      const SizedBox(height: 40),
                      Text(
                        _controller.loadingMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
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
    final screenHeight = MediaQuery.of(context).size.height;
    // Gradient covers ~62% of screen like the reference
    final gradientHeight = screenHeight * 0.62;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Gradient area + overlapping white card ──
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Gradient background
                _buildGradientBackground(gradientHeight),
                // Content on gradient
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      _buildAppBar(),
                      const SizedBox(height: 24),
                      _buildClock(),
                      const SizedBox(height: 32),
                      _buildClockButton(),
                      const SizedBox(height: 20),
                      _buildLocationBadge(),
                    ],
                  ),
                ),
                // White card overlapping the gradient
                Positioned(
                  left: 0,
                  right: 0,
                  top: gradientHeight - 50,
                  child: _buildStatusCard(),
                ),
              ],
            ),
            // Extra space for the overlapping card
            const SizedBox(height: 60),
            // Photo sections (scrollable below)
            _buildPhotoSections(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── Gradient Background ──────────────────────────────────

  Widget _buildGradientBackground(double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B7CF6), Color(0xFF6B8CF0), Color(0xFF5A9AEF)],
        ),
      ),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Company / user name
          Text(
            _employeeName.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          // Action icons
          Row(
            children: [
              const SizedBox(width: 12),
              _buildAppBarIcon(Icons.logout_rounded, () async {
                await TokenStorage.clearToken();
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // ─── Clock Display ────────────────────────────────────────

  Widget _buildClock() {
    return Column(
      children: [
        Text(
          _currentTime,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 64,
            fontWeight: FontWeight.w200,
            letterSpacing: 6,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _currentDate,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
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

    final List<Color> gradientColors = allDone
        ? [const Color(0xFF9CA3AF), const Color(0xFF6B7280)]
        : showClockOut
        ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
        : [const Color(0xFFB794F6), const Color(0xFF9B6DFF)];

    final Color glowColor = allDone
        ? Colors.grey
        : showClockOut
        ? const Color(0xFFEF4444)
        : const Color(0xFFA78BFA);

    return AnimatedBuilder(
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
                return Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: _ringAnimation.value * 0.5,
                      ),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 145,
                      height: 145,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            allDone
                                ? Icons.check_circle_outline
                                : showClockOut
                                ? Icons.logout_rounded
                                : Icons.fingerprint,
                            color: Colors.white,
                            size: 44,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ─── Location Badge ───────────────────────────────────────

  Widget _buildLocationBadge() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_on, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _controller.alamatMasuk ?? 'Menunggu lokasi...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Status Card (white, overlaps gradient) ───────────────

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatusItem(
            icon: Icons.login_rounded,
            iconColor: const Color(0xFF22C55E),
            iconBg: const Color(0xFFDCFCE7),
            time: _controller.clockInTime,
            label: 'Clock In',
          ),
          _buildStatusDivider(),
          _buildStatusItem(
            icon: Icons.logout_rounded,
            iconColor: const Color(0xFFEF4444),
            iconBg: const Color(0xFFFEE2E2),
            time: _controller.clockOutTime,
            label: 'Clock Out',
          ),
          _buildStatusDivider(),
          _buildStatusItem(
            icon: Icons.timer_outlined,
            iconColor: const Color(0xFF6C63FF),
            iconBg: const Color(0xFFEDE9FE),
            time: _calculateDuration(),
            label: 'Durasi',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String time,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          time,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDivider() {
    return Container(width: 1, height: 60, color: Colors.grey.shade200);
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

  // ─── Photo Sections ───────────────────────────────────────

  Widget _buildPhotoSections() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          if (_controller.photoMasuk != null) ...[
            _buildPhotoCard(
              label: 'Foto Absen Masuk',
              photo: _controller.photoMasuk!,
              alamat: _controller.alamatMasuk,
              timestamp: _controller.timestampMasuk,
              color: const Color(0xFF22C55E),
            ),
            const SizedBox(height: 16),
          ],
          if (_controller.photoPulang != null) ...[
            _buildPhotoCard(
              label: 'Foto Absen Pulang',
              photo: _controller.photoPulang!,
              alamat: _controller.alamatPulang,
              timestamp: _controller.timestampPulang,
              color: const Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoCard({
    required String label,
    required File photo,
    String? alamat,
    DateTime? timestamp,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF1A1D3A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              photo,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                timestamp != null
                    ? DateFormat('dd-MM-yyyy HH:mm').format(timestamp)
                    : '-',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          if (alamat != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    alamat,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Bottom Navigation Bar ────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
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
              if (mounted) setState(() => _currentNavIndex = 0);
            } else if (index == 3) {
              final updatedEmployee = await Navigator.push<Map<String, dynamic>>(
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
              if (mounted) {
                if (updatedEmployee != null) {
                  _applyUpdatedEmployee(updatedEmployee);
                }
                setState(() => _currentNavIndex = 0);
              }
            } else {
              setState(() => _currentNavIndex = index);
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF6C63FF),
          unselectedItemColor: const Color(0xFFADB5BD),
          selectedFontSize: 12,
          unselectedFontSize: 11,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_rounded),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz),
              label: 'More',
            ),
          ],
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
