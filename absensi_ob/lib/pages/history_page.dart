import 'package:flutter/material.dart';
import 'package:absensi_ob/models/attendance_record.dart';
import 'package:absensi_ob/core/app_colors.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatelessWidget {
  final List<AttendanceRecord> records;

  const HistoryPage({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    final sortedRecords = [...records]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final masukCount = records.where((r) => r.type == 'Masuk').length;
    final pulangCount = records.where((r) => r.type == 'Pulang').length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text(
          'Attendance',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: records.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_busy_rounded,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Belum ada riwayat presensi',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Data clock in dan clock out akan muncul setelah kamu melakukan presensi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _SummaryCard(
                  total: records.length,
                  masuk: masukCount,
                  pulang: pulangCount,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Riwayat terbaru',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ...sortedRecords.map(_HistoryTile.new),
              ],
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int total;
  final int masuk;
  final int pulang;

  const _SummaryCard({
    required this.total,
    required this.masuk,
    required this.pulang,
  });

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: _SummaryItem(
              icon: Icons.fact_check_rounded,
              label: 'Total',
              value: '$total',
              color: AppColors.primary,
            ),
          ),
          Expanded(
            child: _SummaryItem(
              icon: Icons.login_rounded,
              label: 'Masuk',
              value: '$masuk',
              color: AppColors.success,
            ),
          ),
          Expanded(
            child: _SummaryItem(
              icon: Icons.logout_rounded,
              label: 'Pulang',
              value: '$pulang',
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final AttendanceRecord record;

  const _HistoryTile(this.record);

  @override
  Widget build(BuildContext context) {
    final isMasuk = record.type == 'Masuk';
    final color = isMasuk ? AppColors.success : AppColors.error;
    final title = isMasuk ? 'Clock In' : 'Clock Out';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isMasuk ? Icons.login_rounded : Icons.logout_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(record.timestamp),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  DateFormat('EEEE, dd MMM yyyy').format(record.timestamp),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                _InfoLine(
                  icon: Icons.person_rounded,
                  text: '${record.name} - ${record.phoneNumber}',
                ),
                const SizedBox(height: 6),
                _InfoLine(
                  icon: Icons.location_on_rounded,
                  text: record.locationName,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
