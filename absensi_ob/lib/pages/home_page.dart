import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/attendance_controller.dart';
import '../core/app_constants.dart';
import '../core/app_theme.dart';
import '../services/session_manager.dart';

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
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
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

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _updateTime() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm').format(now);
      _currentDate = DateFormat('EEEE, dd MMM yyyy').format(now);
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _ctrl.removeListener(_onControllerUpdate);
    _pulseController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAppBar(),
              const SizedBox(height: 16),
              _buildMainAttendanceCard(),
              const SizedBox(height: 12),
              _buildStatusCard(),
              const SizedBox(height: 12),
              _buildPerformanceSection(),
              const SizedBox(height: 112),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final initial = widget.name.trim().isEmpty
        ? '?'
        : widget.name.trim()[0].toUpperCase();

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: AppTheme.gradientArmyGreen),
            boxShadow: [AppTheme.buttonShadow],
          ),
          clipBehavior: Clip.antiAlias,
          child:
              widget.profilePhotoUrl != null &&
                  widget.profilePhotoUrl!.isNotEmpty
              ? Image.network(
                  widget.profilePhotoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _AvatarInitial(initial),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.name,
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainAttendanceCard() {
    final hasClockedIn = _ctrl.isClockedIn;
    final hasClockedOut = _ctrl.clockOutTime != '--:--';
    final showClockOut = hasClockedIn && !hasClockedOut;
    final allDone = hasClockedIn && hasClockedOut;

    final label = allDone
        ? 'SELESAI'
        : showClockOut
        ? 'CLOCK OUT'
        : 'CLOCK IN';
    final VoidCallback? onTap = allDone
        ? null
        : showClockOut
        ? widget.onClockOut
        : widget.onClockIn;
    final btnColor = allDone
        ? AppTheme.textMuted
        : showClockOut
        ? AppTheme.btnRed
        : AppTheme.btnGreen;
    final btnColorDark = allDone
        ? AppTheme.textLight
        : showClockOut
        ? const Color(0xFFB63A48)
        : AppTheme.btnGreenDark;
    final btnIcon = allDone
        ? Icons.check_circle_outline_rounded
        : Icons.face_retouching_natural_rounded;

    final parts = _currentTime.split(':');
    final hours = parts.isNotEmpty ? parts[0] : '--';
    final minutes = parts.length > 1 ? parts[1] : '--';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppTheme.clayDecoration(radius: AppTheme.radiusXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentDate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          hours,
                          style: TextStyle(
                            color: AppTheme.textDark,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          ':',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          minutes,
                          style: TextStyle(
                            color: AppTheme.textDark,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusBadge(
                label: allDone
                    ? 'Sesi selesai'
                    : showClockOut
                    ? 'Sedang bekerja'
                    : 'Belum absen',
                color: allDone
                    ? AppTheme.textMuted
                    : showClockOut
                    ? AppTheme.warning
                    : AppTheme.success,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final buttonSize = (constraints.maxWidth * 0.48).clamp(
                    140.0,
                    220.0,
                  );
                  final mainSize = buttonSize * 0.643;
                  final ring1 = buttonSize * 0.976;
                  final ring2 = buttonSize * 0.833;
                  final ring3 = buttonSize * 0.690;

                  return AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = allDone ? 1.0 : _pulseAnimation.value;
                      return Transform.scale(
                        scale: scale,
                        child: GestureDetector(
                          onTap: onTap,
                          child: AnimatedBuilder(
                            animation: _ringController,
                            builder: (context, child) {
                              return SizedBox(
                                width: buttonSize,
                                height: buttonSize,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    _buildRing(
                                      ring1,
                                      1.5,
                                      _ringAnimation.value * 0.35,
                                      btnColor,
                                    ),
                                    _buildRing(
                                      ring2,
                                      2.2,
                                      _ringAnimation.value * 0.55,
                                      btnColor,
                                    ),
                                    _buildRing(ring3, 1.5, 0.3, btnColor),
                                    Container(
                                      width: mainSize,
                                      height: mainSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [btnColor, btnColorDark],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: btnColor.withValues(
                                              alpha: 0.36,
                                            ),
                                            blurRadius: 28,
                                            spreadRadius: -2,
                                            offset: const Offset(0, 12),
                                          ),
                                          BoxShadow(
                                            color: Colors.white.withValues(
                                              alpha: 0.18,
                                            ),
                                            blurRadius: 8,
                                            spreadRadius: -6,
                                            offset: const Offset(-4, -4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            btnIcon,
                                            color: Colors.white,
                                            size: 52,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            label,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.2,
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
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: AppTheme.clayPrimary,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _ctrl.alamatMasuk ?? 'Menunggu lokasi GPS...',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRing(double size, double width, double alpha, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: alpha),
          width: width,
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: AppTheme.clayDecoration(radius: AppTheme.radiusLg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatusItem(
            icon: Icons.login_rounded,
            iconBgColor: AppTheme.success.withValues(alpha: 0.12),
            iconColor: AppTheme.success,
            time: _ctrl.clockInTime,
            label: 'Clock In',
            accentColor: AppTheme.success,
          ),
          Container(width: 1, height: 42, color: AppTheme.dividerColor),
          _StatusItem(
            icon: Icons.logout_rounded,
            iconBgColor: AppTheme.error.withValues(alpha: 0.12),
            iconColor: AppTheme.error,
            time: _ctrl.clockOutTime,
            label: 'Clock Out',
            accentColor: AppTheme.error,
          ),
          Container(width: 1, height: 42, color: AppTheme.dividerColor),
          _StatusItem(
            icon: Icons.timer_outlined,
            iconBgColor: AppTheme.info.withValues(alpha: 0.12),
            iconColor: AppTheme.info,
            time: _calculateDuration(),
            label: 'Durasi Kerja',
            accentColor: AppTheme.info,
          ),
        ],
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

    final monthRecords = records
        .where(
          (r) =>
              r.timestamp.month == currentMonth &&
              r.timestamp.year == currentYear &&
              r.timestamp.weekday <= DateTime.friday &&
              r.type == 'Masuk',
        )
        .toList();

    final presentDays = <String>{};
    final onTimeDays = <String>{};

    for (final r in monthRecords) {
      final dayKey = DateFormat('yyyy-MM-dd').format(r.timestamp);
      presentDays.add(dayKey);

      final minutes = r.timestamp.hour * 60 + r.timestamp.minute;
      final startMinutes =
          AppConstants.clockInStartHour * 60 + AppConstants.clockInStartMinute;
      final endMinutes =
          AppConstants.clockInEndHour * 60 + AppConstants.clockInEndMinute;
      if (minutes >= startMinutes && minutes <= endMinutes) {
        onTimeDays.add(dayKey);
      }
    }

    final totalPresent = presentDays.length;
    final onTimeCount = onTimeDays.length;
    final lateCount = totalPresent - onTimeCount;
    final onTimePct = totalPresent > 0
        ? (onTimeCount / totalPresent) * 100
        : 100.0;
    final monthWorkdays = _countWorkdaysInMonth(currentYear, currentMonth);

    return {
      'totalPresent': totalPresent,
      'onTimePct': onTimePct,
      'lateCount': lateCount,
      'monthCount': totalPresent,
      'monthWorkdays': monthWorkdays,
    };
  }

  int _countWorkdaysInMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0).day;
    var count = 0;

    for (var day = 1; day <= lastDay; day++) {
      final date = DateTime(year, month, day);
      if (date.weekday <= DateTime.friday) {
        count++;
      }
    }

    return count;
  }

  String _getIndonesianMonthYear() {
    final now = DateTime.now();
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  Widget _buildPerformanceSection() {
    final metrics = _calculatePerformanceMetrics();
    final totalPresent = metrics['totalPresent'] as int;
    final onTimePct = metrics['onTimePct'] as double;
    final lateCount = metrics['lateCount'] as int;
    final monthCount = metrics['monthCount'] as int;
    final monthWorkdays = metrics['monthWorkdays'] as int;

    var performanceLabel = 'Cukup';
    if (onTimePct >= 95) {
      performanceLabel = 'Sangat Baik';
    } else if (onTimePct >= 85) {
      performanceLabel = 'Baik';
    }

    final monthProgress = monthWorkdays > 0
        ? (monthCount / monthWorkdays).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.clayDecoration(radius: AppTheme.radiusXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PERFORMA BULAN INI',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getIndonesianMonthYear(),
                      style: TextStyle(
                        color: AppTheme.textDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.armyGreenLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  performanceLabel,
                  style: TextStyle(
                    color: AppTheme.armyGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progres Bulan Ini',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$monthCount/$monthWorkdays Hari',
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 7,
              child: LinearProgressIndicator(
                value: monthProgress,
                backgroundColor: AppTheme.surfaceAlt,
                color: AppTheme.armyGreen,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPerformanceMetric(
                value: '$totalPresent Hari',
                label: 'Hadir',
                icon: Icons.check_circle_outline_rounded,
                iconColor: AppTheme.success,
                bgColor: AppTheme.success.withValues(alpha: 0.12),
              ),
              const SizedBox(width: 8),
              _buildPerformanceMetric(
                value: '${onTimePct.toStringAsFixed(0)}%',
                label: 'Tepat Waktu',
                icon: Icons.bolt_rounded,
                iconColor: AppTheme.warning,
                bgColor: AppTheme.warning.withValues(alpha: 0.12),
              ),
              const SizedBox(width: 8),
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textDark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          time,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
