import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

/// Model untuk summary row data
class SummaryRowData {
  final String label;
  final String value;

  const SummaryRowData(this.label, this.value);
}

/// Reusable summary card untuk menampilkan ringkasan request
class RequestSummaryCard extends StatelessWidget {
  final List<SummaryRowData> rows;

  const RequestSummaryCard({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.summarize_rounded,
                color: AppTheme.armyGreen,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Ringkasan',
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...rows.asMap().entries.map((entry) {
            final isLast = entry.key == rows.length - 1;
            return Column(
              children: [
                _SummaryRow(label: entry.value.label, value: entry.value.value),
                if (!isLast) ...[
                  const SizedBox(height: 10),
                  Divider(color: AppTheme.border, height: 1),
                  const SizedBox(height: 10),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}

/// Internal widget untuk row dalam summary
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
