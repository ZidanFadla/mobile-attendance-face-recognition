import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';

/// Reusable date picker tile untuk form request (Leave & Cash Advance)
class RequestDatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  /// Jika true, menampilkan layout compact (label di atas, icon + tanggal di bawah).
  /// Jika false, menampilkan layout full (icon di kiri, label + tanggal di kanan).
  final bool compact;

  const RequestDatePickerTile({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final display = value == null
        ? 'Pilih tanggal'
        : DateFormat('dd MMM yyyy').format(value!);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: compact ? _compactLayout(display) : _fullLayout(display),
      ),
    );
  }

  /// Layout compact: label di atas, icon + tanggal di bawah (digunakan di LeaveRequestPage)
  Widget _compactLayout(String display) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        const SizedBox(height: 7),
        Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 17,
              color: AppTheme.armyGreen,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                display,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Layout full: icon di kiri, label + tanggal di kanan (digunakan di CashAdvanceRequestPage)
  Widget _fullLayout(String display) {
    return Row(
      children: [
        Icon(Icons.calendar_month_rounded, size: 18, color: AppTheme.armyGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                display,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
