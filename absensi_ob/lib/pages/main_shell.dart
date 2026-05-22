import 'dart:io';
import 'package:flutter/material.dart';
import '../controllers/attendance_controller.dart';
import '../core/app_constants.dart';
import '../core/app_theme.dart';
import '../services/session_manager.dart';
import '../services/message_service.dart';
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
    _controller.addListener(() => setState(() {}));
    _controller.init().then((needsRegistration) {
      if (needsRegistration && mounted) _showRegisterFaceDialog();
    });

    // Muat riwayat absensi dari database backend
    SessionManager.loadFromApi(_name).then((_) {
      if (mounted) setState(() {});
    });

    // Start polling admin messages immediately on app startup
    MessageService.startPolling(
      onMessages: (_) {},
      onUnreadCount: (_) {},
    );
  }

  @override
  void dispose() {
    MessageService.stopPolling();
    _controller.dispose();
    super.dispose();
  }

  // ── Flows ──────────────────────────────────────────────────

  Future<void> _onClockIn() async {
    final path = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const FaceScanSimplePage()),
    );
    if (path == null || !mounted) return;
    final result = await _controller.clockIn(File(path));
    if (mounted) _showResultDialog(result.message, result.success);
  }

  Future<void> _onClockOut() async {
    final path = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const FaceScanSimplePage()),
    );
    if (path == null || !mounted) return;
    final result = await _controller.clockOut(File(path));
    if (mounted) _showResultDialog(result.message, result.success);
  }

  Future<void> _onRegisterFace() async {
    setState(() => _currentIndex = 0);

    final List<File> photos = [];
    final instructions = AppConstants.faceRegisterInstructions;

    for (int i = 0; i < 3; i++) {
      if (!mounted) return;
      final path = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => FaceScanSimplePage(instruction: instructions[i]),
        ),
      );
      if (path == null) {
        if (mounted) _showResultDialog('Registrasi dibatalkan', false);
        return;
      }
      photos.add(File(path));
      if (i < 2 && mounted) await _showPhotoProgressDialog(i + 1);
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
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Registrasi Wajah',
          style: TextStyle(color: AppTheme.textDark),
        ),
        content: Text(
          'Wajah kamu belum terdaftar. Silakan registrasi wajah terlebih dahulu untuk bisa absen.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _onRegisterFace();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.btnGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
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
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: AppTheme.success, size: 56),
              const SizedBox(height: 16),
              Text(
                '✅ Foto $photoNumber/3 berhasil!\nSiap untuk foto berikutnya.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppTheme.textDark),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.btnGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? AppTheme.success : AppTheme.error,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppTheme.textDark),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: success ? AppTheme.success : AppTheme.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
    return Container(
      color: Colors.black54,
      child: Center(
        child: Dialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.btnGreen),
                const SizedBox(height: 40),
                Text(
                  _controller.loadingMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.navSurface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppTheme.navSurface,
              selectedItemColor: AppTheme.btnGreen,
              unselectedItemColor: AppTheme.textMuted,
              selectedFontSize: 12,
              unselectedFontSize: 11,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
              elevation: 0,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_rounded),
                  label: 'Absensi',
                ),
                BottomNavigationBarItem(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_outlined),
                      ValueListenableBuilder<int>(
                        valueListenable: MessageService.unreadCountNotifier,
                        builder: (context, unreadCount, _) {
                          if (unreadCount <= 0) return const SizedBox.shrink();
                          return Positioned(
                            right: -4,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
                              ),
                              child: Center(
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  label: 'Notifikasi',
                ),
                const BottomNavigationBarItem(
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
}
