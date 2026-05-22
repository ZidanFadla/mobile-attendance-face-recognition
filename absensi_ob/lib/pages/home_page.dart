import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/attendance_controller.dart';
import '../core/app_theme.dart';
import '../services/session_manager.dart';

/// Pure display widget for the Home tab.
/// All business logic is in [MainShell].
class HomePage extends StatefulWidget {
  final AttendanceController controller;
  final String name;
  final String phoneNumber;
  final String? profilePhotoUrl;
  final VoidCallback onClockIn;
  final VoidCallback onClockOut;

  const HomePage({
    super.key,
    required this.controller,
    required this.name,
    required this.phoneNumber,
    this.profilePhotoUrl,
    required this.onClockIn,
    required this.onClockOut,
  });

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late Timer _clockTimer;
  String _currentTime = '';
  String _currentDate = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;

  AttendanceController get _ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onControllerUpdate);

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

  void _onControllerUpdate() => setState(() {});

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm').format(now);
      _currentDate = DateFormat('EEEE, dd MMM yyyy').format(now);
    });
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerUpdate);
    _clockTimer.cancel();
    _pulseController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
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
              const SizedBox(height: 20),
              _buildPerformanceSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── App Bar ────────────────────────────────────────────────

  Widget _buildAppBar() {
    final initial = widget.name.trim().isEmpty
        ? '?'
        : widget.name.trim()[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: AppTheme.gradientArmyGreen),
            ),
            clipBehavior: Clip.antiAlias,
            child:
                widget.profilePhotoUrl != null &&
                    widget.profilePhotoUrl!.isNotEmpty
                ? Image.network(
                    widget.profilePhotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, e, st) => _AvatarInitial(initial),
                  )
                : _AvatarInitial(initial),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTheme.greeting(),
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.name,
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Date Badge ─────────────────────────────────────────────

  Widget _buildDateBadge() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.btnGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _currentDate,
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Big Clock ──────────────────────────────────────────────

  Widget _buildBigClock() {
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
            style: TextStyle(
              color: AppTheme.textDark,
              fontSize: 72,
              fontWeight: FontWeight.w900,
              height: 0.95,
              letterSpacing: -2,
            ),
          ),
          Text(
            minutes,
            style: TextStyle(
              color: AppTheme.textDark,
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

  // ── Clock Button ───────────────────────────────────────────

  Widget _buildClockButton() {
    final bool hasClockedIn = _ctrl.isClockedIn;
    final bool hasClockedOut = _ctrl.clockOutTime != '--:--';
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
        ? widget.onClockOut
        : widget.onClockIn;
    final Color btnColor = allDone
        ? const Color(0xFF4A5568)
        : showClockOut
        ? AppTheme.btnRed
        : AppTheme.btnGreen;
    final Color btnColorDark = allDone
        ? const Color(0xFF3A4555)
        : showClockOut
        ? const Color(0xFF6B2A2A)
        : AppTheme.btnGreenDark;
    final IconData btnIcon = allDone
        ? Icons.check_circle_outline
        : showClockOut
        ? Icons.logout_rounded
        : Icons.crop_square_rounded;

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
                    width: 290,
                    height: 290,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildRing(230, 1, _ringAnimation.value * 0.3),
                        _buildRing(176, 1.5, _ringAnimation.value * 0.5),
                        _buildRing(158, 1, 0.25),
                        // Main button
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

  Widget _buildRing(double size, double width, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.ringColor.withValues(alpha: alpha),
          width: width,
        ),
      ),
    );
  }

  // ── Location Badge ─────────────────────────────────────────

  Widget _buildLocationBadge() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.location_on, color: AppTheme.textMuted, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _ctrl.alamatMasuk ?? 'Menunggu lokasi...',
                style: TextStyle(
                  color: AppTheme.textMuted,
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

  // ── Status Card ────────────────────────────────────────────

  Widget _buildStatusCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatusItem(
              icon: Icons.login_rounded,
              iconBgColor: AppTheme.btnGreenDark.withValues(alpha: 0.5),
              iconColor: AppTheme.btnGreen,
              time: _ctrl.clockInTime,
              label: 'Clock In',
              accentColor: AppTheme.success,
            ),
            Container(width: 1, height: 56, color: AppTheme.dividerColor),
            _StatusItem(
              icon: Icons.logout_rounded,
              iconBgColor: const Color(0xFF5A2020),
              iconColor: AppTheme.error,
              time: _ctrl.clockOutTime,
              label: 'Clock Out',
              accentColor: AppTheme.error,
            ),
            Container(width: 1, height: 56, color: AppTheme.dividerColor),
            _StatusItem(
              icon: Icons.timer_outlined,
              iconBgColor: const Color(0xFF1A3A50),
              iconColor: AppTheme.info,
              time: _calculateDuration(),
              label: 'Durasi',
              accentColor: AppTheme.info,
            ),
          ],
        ),
      ),
    );
  }

  String _calculateDuration() {
    if (_ctrl.clockInTime == '--:--') return '--:--';
    final start = _ctrl.timestampMasuk;
    if (start == null) return '--:--';

    final end = _ctrl.clockOutTime != '--:--'
        ? _ctrl.timestampPulang
        : DateTime.now();
    if (end == null) return '--:--';

    final diff = end.difference(start);
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  Map<String, dynamic> _calculatePerformanceMetrics() {
    final records = SessionManager.getRecords(widget.name);
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Filter records for current month of type 'Masuk'
    final monthRecords = records.where((r) =>
        r.timestamp.month == currentMonth &&
        r.timestamp.year == currentYear &&
        r.type == 'Masuk').toList();

    final totalPresent = monthRecords.length;

    // Calculate on time count (before 08:00 AM)
    int onTimeCount = 0;
    for (final r in monthRecords) {
      final hour = r.timestamp.hour;
      final minute = r.timestamp.minute;
      if (hour < 8 || (hour == 8 && minute == 0)) {
        onTimeCount++;
      }
    }

    final lateCount = totalPresent - onTimeCount;
    final onTimePct = totalPresent > 0 ? (onTimeCount / totalPresent) * 100 : 100.0;

    // Filter records for the current week (Monday to Sunday)
    final daysToSubtract = now.weekday - 1;
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));
    final sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    final weekRecords = records.where((r) =>
        r.timestamp.isAfter(monday.subtract(const Duration(seconds: 1))) &&
        r.timestamp.isBefore(sunday.add(const Duration(seconds: 1))) &&
        r.type == 'Masuk').toList();

    // Distinct week days
    final weekDays = weekRecords.map((r) => r.timestamp.day).toSet();
    final weekCount = weekDays.length;

    return {
      'totalPresent': totalPresent,
      'onTimePct': onTimePct,
      'lateCount': lateCount,
      'weekCount': weekCount,
    };
  }

  String _getIndonesianMonthYear() {
    final now = DateTime.now();
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  Widget _buildPerformanceSection() {
    final metrics = _calculatePerformanceMetrics();
    final int totalPresent = metrics['totalPresent'] as int;
    final double onTimePct = metrics['onTimePct'] as double;
    final int lateCount = metrics['lateCount'] as int;
    final int weekCount = metrics['weekCount'] as int;

    // Determine performance level label
    String performanceLabel = 'Cukup';
    if (onTimePct >= 95) {
      performanceLabel = 'Sangat Baik';
    } else if (onTimePct >= 85) {
      performanceLabel = 'Baik';
    }

    final double weekProgress = (weekCount / 5.0).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
          boxShadow: [AppTheme.cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PERFORMA BULAN INI',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getIndonesianMonthYear(),
                      style: TextStyle(
                        color: AppTheme.textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.armyGreenLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    performanceLabel,
                    style: TextStyle(
                      color: AppTheme.armyGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progres Absensi Minggu Ini',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$weekCount/5 Hari',
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 8,
                child: LinearProgressIndicator(
                  value: weekProgress,
                  backgroundColor: AppTheme.surfaceAlt,
                  color: AppTheme.armyGreen,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                _buildPerformanceMetric(
                  value: '$totalPresent Hari',
                  label: 'Hadir',
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: AppTheme.success,
                  bgColor: AppTheme.success.withValues(alpha: 0.12),
                ),
                const SizedBox(width: 12),
                _buildPerformanceMetric(
                  value: '${onTimePct.toStringAsFixed(0)}%',
                  label: 'Tepat Waktu',
                  icon: Icons.bolt_rounded,
                  iconColor: AppTheme.warning,
                  bgColor: AppTheme.warning.withValues(alpha: 0.12),
                ),
                const SizedBox(width: 12),
                _buildPerformanceMetric(
                  value: '${lateCount}x',
                  label: 'Terlambat',
                  icon: Icons.error_outline_rounded,
                  iconColor: AppTheme.error,
                  bgColor: AppTheme.error.withValues(alpha: 0.12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetric({
    required String value,
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable Widgets ─────────────────────────────────────────

class _AvatarInitial extends StatelessWidget {
  final String initial;
  const _AvatarInitial(this.initial);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String time;
  final String label;
  final Color accentColor;

  const _StatusItem({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.time,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
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
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
