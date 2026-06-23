import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/app_snackbar.dart';

enum RequestHistoryType { leave, cashAdvance }

class RequestHistoryPage extends StatefulWidget {
  final RequestHistoryType type;

  const RequestHistoryPage({super.key, required this.type});

  @override
  State<RequestHistoryPage> createState() => _RequestHistoryPageState();
}

class _RequestHistoryPageState extends State<RequestHistoryPage> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  bool get _isLeave => widget.type == RequestHistoryType.leave;
  String get _title => _isLeave ? 'Riwayat Cuti' : 'Riwayat Kasbon';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final items = _isLeave
          ? await ApiService.fetchLeaveRequests()
          : await ApiService.fetchCashAdvanceRequests();

      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } on TimeoutException {
      _handleError('Server tidak merespons. Pastikan server berjalan.');
    } on FormatException {
      _handleError('Response server tidak valid. Periksa konfigurasi API.');
    } catch (e) {
      _handleError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _handleError(String message) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    showErrorSnackbar(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textDark),
        title: Text(
          _title,
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.armyGreen))
          : RefreshIndicator(
              color: AppTheme.armyGreen,
              onRefresh: _loadHistory,
              child: _items.isEmpty
                  ? _emptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      children: [
                        _SummaryHeader(type: widget.type, items: _items),
                        const SizedBox(height: 14),
                        ..._items.map(
                          (item) => _HistoryCard(
                            item: item,
                            type: widget.type,
                            onOpenAttachment: _openAttachment,
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
      children: [
        Icon(
          _isLeave ? Icons.event_available_rounded : Icons.payments_rounded,
          size: 64,
          color: AppTheme.textMuted.withValues(alpha: 0.28),
        ),
        const SizedBox(height: 14),
        Text(
          _isLeave ? 'Belum ada riwayat cuti' : 'Belum ada riwayat kasbon',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pengajuan yang sudah dikirim akan muncul di sini.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
      ],
    );
  }

  Future<void> _openAttachment(String url) async {
    final lowerUrl = url.toLowerCase();
    final isImage =
        lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.webp');

    if (isImage) {
      if (!mounted) return;
      showDialog(
        context: context,
        useSafeArea: false,
        builder: (_) => _ImagePreviewDialog(imageUrl: url),
      );
    } else {
      // PDF / file lain → tetap buka di browser
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        showErrorSnackbar(context, 'Lampiran tidak bisa dibuka.');
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  Summary Header
// ═══════════════════════════════════════════════════════════════

class _SummaryHeader extends StatelessWidget {
  final RequestHistoryType type;
  final List<Map<String, dynamic>> items;

  const _SummaryHeader({required this.type, required this.items});

  bool get _isLeave => type == RequestHistoryType.leave;

  @override
  Widget build(BuildContext context) {
    final approved = items.where((item) => item['status'] == 'approved').length;
    final pending = items.where((item) => item['status'] == 'pending').length;
    final rejected = items.where((item) => item['status'] == 'rejected').length;
    final active = items
        .where(
          (item) =>
              ['approved', 'disbursed', 'installment'].contains(item['status']),
        )
        .length;
    final paid = items.where((item) => item['status'] == 'paid').length;
    final totalAmount = items
        .where(
          (item) => [
            'approved',
            'disbursed',
            'installment',
            'paid',
          ].contains(item['status']),
        )
        .fold<int>(0, (sum, item) => sum + _asInt(item['amount']));
    final outstandingAmount = items
        .where(
          (item) =>
              ['approved', 'disbursed', 'installment'].contains(item['status']),
        )
        .fold<int>(0, (sum, item) => sum + _asInt(item['outstanding_amount']));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _StatBox(label: 'Total', value: items.length.toString()),
              const SizedBox(width: 10),
              _StatBox(label: 'Menunggu', value: pending.toString()),
              const SizedBox(width: 10),
              _StatBox(
                label: _isLeave ? 'Disetujui' : 'Aktif',
                value: (_isLeave ? approved : active).toString(),
              ),
              const SizedBox(width: 10),
              _StatBox(
                label: _isLeave ? 'Ditolak' : 'Lunas',
                value: (_isLeave ? rejected : paid).toString(),
              ),
            ],
          ),
          if (!_isLeave) ...[
            const SizedBox(height: 12),
            _MoneyRow(label: 'Total kasbon disetujui', amount: totalAmount),
            const SizedBox(height: 8),
            _MoneyRow(label: 'Sisa kasbon aktif', amount: outstandingAmount),
          ],
        ],
      ),
    );
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _MoneyRow extends StatelessWidget {
  final String label;
  final int amount;

  const _MoneyRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        const Spacer(),
        Text(
          NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp ',
            decimalDigits: 0,
          ).format(amount),
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  History Card
// ═══════════════════════════════════════════════════════════════

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final RequestHistoryType type;
  final ValueChanged<String> onOpenAttachment;

  const _HistoryCard({
    required this.item,
    required this.type,
    required this.onOpenAttachment,
  });

  bool get _isLeave => type == RequestHistoryType.leave;

  @override
  Widget build(BuildContext context) {
    final status = item['status']?.toString() ?? 'pending';
    final attachmentUrl = item['attachment_url']?.toString();
    final attachmentName = item['attachment_name']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_statusIcon(status), color: _statusColor(status)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: TextStyle(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle,
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item['reason']?.toString() ?? '-',
            style: TextStyle(
              color: AppTheme.textDark,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (attachmentUrl != null && attachmentUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            _AttachmentPreview(
              url: attachmentUrl,
              name: attachmentName,
              onTap: () => onOpenAttachment(attachmentUrl),
            ),
          ],
          if ((item['admin_note']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Catatan admin: ${item['admin_note']}',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  String get _title {
    if (_isLeave) return item['leave_type']?.toString() ?? 'Pengajuan Cuti';

    final amount = _asCurrency(item['amount']);
    return amount == '-' ? 'Pengajuan Kasbon' : amount;
  }

  String get _subtitle {
    if (_isLeave) {
      final start = _formatDate(item['start_date']);
      final end = _formatDate(item['end_date']);
      final duration = item['is_half_day'] == true
          ? 'Setengah hari'
          : '${item['duration_days'] ?? 1} hari';
      return '$start - $end - $duration';
    }

    final needed = _formatDate(item['needed_date']);
    final purpose = item['purpose']?.toString() ?? 'Kasbon';
    final outstanding = _asCurrency(item['outstanding_amount']);
    final installment =
        '${item['installment_paid'] ?? 0}/${item['installment_count'] ?? 1} cicilan';
    return '$purpose - Dibutuhkan $needed - Sisa $outstanding - $installment';
  }

  String _formatDate(dynamic raw) {
    final value = raw?.toString();
    if (value == null || value.isEmpty) return '-';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd MMM yyyy').format(parsed);
  }

  String _asCurrency(dynamic raw) {
    final amount = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
    if (amount == null) return '-';
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  Color _statusColor(String status) {
    return switch (status) {
      'approved' => AppTheme.success,
      'rejected' => AppTheme.error,
      'disbursed' => Colors.blue,
      'installment' => Colors.indigo,
      'paid' => AppTheme.textMuted,
      _ => const Color(0xFFF59E0B),
    };
  }

  IconData _statusIcon(String status) {
    return switch (status) {
      'approved' => Icons.check_circle_rounded,
      'rejected' => Icons.cancel_rounded,
      'disbursed' => Icons.account_balance_wallet_rounded,
      'installment' => Icons.payments_rounded,
      'paid' => Icons.verified_rounded,
      _ => Icons.hourglass_top_rounded,
    };
  }
}

// ═══════════════════════════════════════════════════════════════
//  Status Chip
// ═══════════════════════════════════════════════════════════════

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved' => AppTheme.success,
      'rejected' => AppTheme.error,
      'disbursed' => Colors.blue,
      'installment' => Colors.indigo,
      'paid' => AppTheme.textMuted,
      _ => const Color(0xFFF59E0B),
    };
    final label = switch (status) {
      'approved' => 'Disetujui',
      'rejected' => 'Ditolak',
      'disbursed' => 'Dicairkan',
      'installment' => 'Cicilan',
      'paid' => 'Lunas',
      _ => 'Menunggu',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Attachment Preview - Thumbnail dengan tap to open
// ═══════════════════════════════════════════════════════════════

class _AttachmentPreview extends StatelessWidget {
  final String url;
  final String? name;
  final VoidCallback onTap;

  const _AttachmentPreview({
    required this.url,
    required this.name,
    required this.onTap,
  });

  bool get _isImage {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            // Thumbnail untuk gambar
            if (_isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, st) => Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.armyGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.image_rounded,
                      color: AppTheme.armyGreen,
                      size: 22,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.armyGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.attach_file_rounded,
                  color: AppTheme.armyGreen,
                  size: 22,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name?.isNotEmpty == true ? name! : 'Lampiran',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isImage
                        ? 'Ketuk untuk melihat foto'
                        : 'Ketuk untuk membuka',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              _isImage ? Icons.zoom_in_rounded : Icons.open_in_new_rounded,
              color: AppTheme.armyGreen,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Image Preview Dialog - Fullscreen dengan zoom
// ═══════════════════════════════════════════════════════════════

class _ImagePreviewDialog extends StatelessWidget {
  final String imageUrl;

  const _ImagePreviewDialog({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          // Gambar dengan zoom
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  final total = loadingProgress.expectedTotalBytes;
                  final loaded = loadingProgress.cumulativeBytesLoaded;
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          value: total != null ? loaded / total : null,
                          color: AppTheme.armyGreen,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Memuat gambar...',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                },
                errorBuilder: (_, e, st) => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white38,
                        size: 64,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Gagal memuat gambar',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tombol close
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // Hint pinch to zoom
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                'Cubit untuk zoom',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
