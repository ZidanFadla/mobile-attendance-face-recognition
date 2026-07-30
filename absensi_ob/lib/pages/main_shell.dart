import 'dart:io';
import 'package:flutter/material.dart';
import '../controllers/attendance_controller.dart';
import '../core/app_constants.dart';
import '../core/app_theme.dart';
import '../services/face_recognition_service.dart';
import '../services/session_manager.dart';
import '../services/message_service.dart';
import '../services/offline_attendance_queue.dart';
import '../widgets/design_system/soft_components.dart';
import 'face_scan_simple_page.dart';
import 'home_page.dart';
import 'history_page.dart';
import 'messages_page.dart';
import 'more_page.dart';

/// Root shell with persistent bottom navigation.
/// Owns the [AttendanceController] and orchestrates all flows.
class MainShell extends StatefulWidget {
  final String name;
  final String phoneNumber;
  final String? profilePhotoUrl;

  const MainShell({
    super.key,
    required this.name,
    required this.phoneNumber,
    this.profilePhotoUrl,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late String _name;
  late String _phone;
  String? _photoUrl;
  late final AttendanceController _controller;

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _phone = widget.phoneNumber;
    _photoUrl = widget.profilePhotoUrl;

    _controller = AttendanceController(name: _name, phoneNumber: _phone);
    _controller.addListener(() {
      if (mounted) setState(() {});
    });

    // Initialize on-device face recognition model
    FaceRecognitionService.init().catchError((e) {
      debugPrint('⚠️ Face model init failed: $e');
    });

    _controller.init().then((needsRegistration) {
      if (needsRegistration && mounted) _showRegisterFaceDialog();
    });

    // Sync offline attendance queue
    OfflineAttendanceQueue.syncAll();

    // Start polling admin messages immediately on app startup
    MessageService.startPolling(onMessages: (_) {}, onUnreadCount: (_) {});
  }

  @override
  void dispose() {
    MessageService.stopPolling();
    _controller.dispose();
    super.dispose();
  }

  // ── Flows ──────────────────────────────────────────────────

  Future<void> _onClockIn() async {
    final synced = await _controller.syncTodayStatusFromServer();
    if (!mounted) return;
    if (synced && _controller.isClockedIn) {
      _showResultDialog(
        'Kamu sudah absen masuk hari ini. Tombol sudah berubah ke Clock Out.',
        false,
      );
      return;
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const FaceScanSimplePage(requireLiveness: true),
      ),
    );
    if (result == null || !mounted) return;
    final path = result['path'] as String;
    final embedding = result['embedding'] as List<double>?;
    if (embedding == null) {
      _showResultDialog('Gagal memproses wajah. Silakan coba lagi.', false);
      return;
    }
    final attendanceResult = await _controller.clockIn(File(path), embedding);
    if (mounted) {
      _showResultDialog(attendanceResult.message, attendanceResult.success);
    }
  }

  Future<void> _onClockOut() async {
    await _controller.syncTodayStatusFromServer();
    if (!mounted) return;
    if (!_controller.isClockedIn) {
      _showResultDialog(
        'Absen masuk terlebih dahulu sebelum absen pulang.',
        false,
      );
      return;
    }
    if (_controller.clockOutTime != '--:--') {
      _showResultDialog('Kamu sudah absen pulang hari ini.', false);
      return;
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const FaceScanSimplePage(requireLiveness: true),
      ),
    );
    if (result == null || !mounted) return;
    final path = result['path'] as String;
    final embedding = result['embedding'] as List<double>?;
    if (embedding == null) {
      _showResultDialog('Gagal memproses wajah. Silakan coba lagi.', false);
      return;
    }
    final attendanceResult = await _controller.clockOut(File(path), embedding);
    if (mounted) {
      _showResultDialog(attendanceResult.message, attendanceResult.success);
    }
  }

  Future<void> _onRegisterFace() async {
    setState(() => _currentIndex = 0);

    final List<File> photos = [];
    final List<List<double>> embeddings = [];
    final instructions = AppConstants.faceRegisterInstructions;

    for (int i = 0; i < 3; i++) {
      if (!mounted) return;
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (_) => FaceScanSimplePage(
            instruction: instructions[i],
            requireLiveness: true,
          ),
        ),
      );
      if (result == null) {
        if (mounted) _showResultDialog('Registrasi dibatalkan', false);
        return;
      }

      final path = result['path'] as String;
      final embedding = result['embedding'] as List<double>?;
      if (embedding == null) {
        if (mounted) {
          _showResultDialog(
            'Foto ${i + 1}: Gagal memproses wajah. Coba lagi.',
            false,
          );
        }
        return;
      }

      photos.add(File(path));
      embeddings.add(embedding);
      if (i < 2 && mounted) await _showPhotoProgressDialog(i + 1);
    }

    if (!mounted) return;
    final regResult = await _controller.registerFace(photos, embeddings);

    if (mounted) {
      _showResultDialog(regResult.message, regResult.success);
      if (!regResult.success) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) _showRegisterFaceDialog();
      }
    }
  }

  void _onEmployeeUpdated(Map<String, dynamic> employee) {
    setState(() {
      _name = employee['name'] as String? ?? _name;
      _phone = employee['phone'] as String? ?? _phone;
      _photoUrl = employee['profile_photo_url'] as String? ?? _photoUrl;
    });
  }

  // ── Dialogs ────────────────────────────────────────────────

  void _showRegisterFaceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: SoftCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.face_retouching_natural_rounded,
                color: AppTheme.clayPrimary,
                size: 54,
              ),
              const SizedBox(height: 18),
              Text(
                'Registrasi Wajah',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Wajah kamu belum terdaftar. Silakan registrasi wajah terlebih dahulu untuk bisa absen.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, height: 1.45),
              ),
              const SizedBox(height: 22),
              ClayButton(
                label: 'Registrasi Sekarang',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  Navigator.pop(ctx);
                  _onRegisterFace();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPhotoProgressDialog(int photoNumber) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: SoftCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppTheme.success,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                'Foto $photoNumber/3 berhasil',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Siap untuk foto berikutnya.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 22),
              ClayButton(
                label: 'Lanjut Foto Berikutnya',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => Navigator.pop(ctx),
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
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: SoftCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                success ? Icons.check_circle_rounded : Icons.error_rounded,
                color: success ? AppTheme.success : AppTheme.error,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              ClayButton(
                label: 'OK',
                icon: success ? Icons.check_rounded : Icons.close_rounded,
                destructive: !success,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              HomePage(
                controller: _controller,
                name: _name,
                phoneNumber: _phone,
                profilePhotoUrl: _photoUrl,
                onClockIn: _onClockIn,
                onClockOut: _onClockOut,
              ),
              HistoryPage(records: SessionManager.getRecords(_name)),
              const MessagesPage(),
              MorePage(
                name: _name,
                phoneNumber: _phone,
                profilePhotoUrl: _photoUrl,
                onRegisterFace: _onRegisterFace,
                onEmployeeUpdated: _onEmployeeUpdated,
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(),
        ),
        if (_controller.isLoading) _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return AnimatedContainer(
      duration: AppTheme.fastTransition,
      color: Colors.black.withValues(alpha: AppTheme.isDark ? 0.58 : 0.32),
      child: Center(child: LoadingCard(message: _controller.loadingMessage)),
    );
  }

  Widget _buildBottomNav() {
    return ValueListenableBuilder<int>(
      valueListenable: MessageService.unreadCountNotifier,
      builder: (context, unreadCount, _) {
        final badge = unreadCount <= 0
            ? null
            : Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppTheme.surface, width: 2),
                ),
                child: Center(
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );

        return SoftNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            const SoftNavigationItem(icon: Icons.home_rounded, label: 'Home'),
            const SoftNavigationItem(
              icon: Icons.calendar_month_rounded,
              label: 'Absensi',
            ),
            SoftNavigationItem(
              icon: Icons.notifications_rounded,
              label: 'Info',
              badge: badge,
            ),
            const SoftNavigationItem(
              icon: Icons.grid_view_rounded,
              label: 'More',
            ),
          ],
        );
      },
    );
  }
}
