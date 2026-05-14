import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/app_snackbar.dart';
import 'request_history_page.dart';

class CashAdvanceRequestPage extends StatefulWidget {
  const CashAdvanceRequestPage({super.key});

  @override
  State<CashAdvanceRequestPage> createState() => _CashAdvanceRequestPageState();
}

class _CashAdvanceRequestPageState extends State<CashAdvanceRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _bankController = TextEditingController();
  final _accountController = TextEditingController();
  final _imagePicker = ImagePicker();

  String _purpose = 'Kebutuhan Mendesak';
  String _repayment = 'Potong Gaji Bulan Ini';
  DateTime? _neededDate;
  File? _attachment;
  String? _attachmentName;
  Map<String, dynamic>? _cashSummary;
  bool _isSubmitting = false;

  final _purposes = const [
    'Kebutuhan Mendesak',
    'Kesehatan',
    'Keluarga',
    'Transportasi',
    'Pendidikan',
    'Lainnya',
  ];

  final _repayments = const [
    'Potong Gaji Bulan Ini',
    'Cicilan 2 Bulan',
    'Cicilan 3 Bulan',
  ];

  @override
  void initState() {
    super.initState();
    _loadCashSummary();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _bankController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _loadCashSummary() async {
    try {
      final summary = await ApiService.fetchCashAdvanceSummary();
      if (!mounted) return;
      setState(() => _cashSummary = summary);
    } catch (_) {
      // Summary is informative; submit validation still happens on server.
    }
  }

  int get _amount {
    final raw = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(raw) ?? 0;
  }

  Future<void> _pickNeededDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _neededDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _neededDate = picked);
  }

  Future<void> _submitCashAdvanceRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_neededDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal dana dibutuhkan.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = await ApiService.submitCashAdvanceRequest(
        amount: _amount,
        purpose: _purpose,
        neededDate: DateFormat('yyyy-MM-dd').format(_neededDate!),
        repaymentMethod: _repayment,
        reason: _reasonController.text.trim(),
        disbursementMethod: _nullableText(_bankController),
        accountNumber: _nullableText(_accountController),
        attachment: _attachment,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (data['success'] == true) {
        _amountController.clear();
        _reasonController.clear();
        _bankController.clear();
        _accountController.clear();
        setState(() {
          _neededDate = null;
          _attachment = null;
          _attachmentName = null;
        });
        _loadCashSummary();
        _showSuccess(data['message'] ?? 'Pengajuan kasbon berhasil dikirim.');
      } else {
        showErrorSnackbar(
          context,
          data['message'] ?? 'Pengajuan kasbon gagal dikirim.',
        );
      }
    } on TimeoutException {
      _handleSubmitError('Server tidak merespons. Pastikan server berjalan.');
    } on FormatException {
      _handleSubmitError(
        'Response server tidak valid. Periksa konfigurasi API.',
      );
    } catch (e) {
      _handleSubmitError(_cleanError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        title: const Text(
          'Pengajuan Kasbon',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Riwayat kasbon',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RequestHistoryPage(
                    type: RequestHistoryType.cashAdvance,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.history_rounded),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _HeaderCard(
              icon: Icons.payments_rounded,
              color: AppTheme.success,
              title: 'Form Kasbon Karyawan',
              subtitle:
                  'Ajukan dana sementara dengan alasan, tanggal kebutuhan, dan rencana pengembalian.',
            ),
            if (_cashSummary != null) ...[
              const SizedBox(height: 14),
              _CashSummaryCard(summary: _cashSummary!),
            ],
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Nominal & Kebutuhan',
              children: [
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    final amount = int.tryParse(value ?? '') ?? 0;
                    if (amount <= 0) return 'Nominal kasbon wajib diisi';
                    return null;
                  },
                  decoration: _inputDecoration(
                    'Nominal Kasbon',
                  ).copyWith(prefixText: 'Rp ', hintText: '500000'),
                ),
                const SizedBox(height: 14),
                _DropdownField(
                  label: 'Tujuan Pengajuan',
                  value: _purpose,
                  items: _purposes,
                  onChanged: (value) => setState(() => _purpose = value),
                ),
                const SizedBox(height: 14),
                _DatePickerTile(
                  label: 'Tanggal Dana Dibutuhkan',
                  value: _neededDate,
                  onTap: _pickNeededDate,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Rencana Pengembalian',
              children: [
                _DropdownField(
                  label: 'Metode Pengembalian',
                  value: _repayment,
                  items: _repayments,
                  onChanged: (value) => setState(() => _repayment = value),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _reasonController,
                  minLines: 4,
                  maxLines: 6,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Alasan kasbon wajib diisi'
                      : null,
                  decoration: _inputDecoration('Alasan Pengajuan').copyWith(
                    hintText:
                        'Jelaskan kebutuhan kasbon secara singkat dan jelas.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Informasi Pencairan',
              children: [
                TextFormField(
                  controller: _bankController,
                  decoration: _inputDecoration(
                    'Nama Bank / Metode',
                  ).copyWith(hintText: 'Contoh: BCA, BRI, Mandiri, Cash'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _accountController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    'Nomor Rekening',
                  ).copyWith(hintText: 'Opsional jika pencairan cash'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _AttachmentTile(
              title: 'Lampiran Pendukung',
              subtitle:
                  _attachmentName ?? 'Foto bukti kebutuhan jika diperlukan.',
              hasAttachment: _attachment != null,
              onTap: _showAttachmentSourceSheet,
              onRemove: _attachment == null
                  ? null
                  : () => setState(() {
                      _attachment = null;
                      _attachmentName = null;
                    }),
            ),
            const SizedBox(height: 14),
            _SummaryCard(
              rows: [
                _SummaryRow(
                  'Nominal',
                  _amount == 0
                      ? '-'
                      : NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(_amount),
                ),
                _SummaryRow('Tujuan', _purpose),
                _SummaryRow('Pengembalian', _repayment),
                _SummaryRow('Status Awal', 'Menunggu persetujuan admin'),
              ],
            ),
            const SizedBox(height: 18),
            _PrimaryButton(
              label: 'Ajukan Kasbon',
              icon: Icons.send_rounded,
              isLoading: _isSubmitting,
              onPressed: _submitCashAdvanceRequest,
            ),
          ],
        ),
      ),
    );
  }

  String? _nullableText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  void _handleSubmitError(String message) {
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    showErrorSnackbar(context, message);
  }

  String _cleanError(Object error) {
    final message = error.toString();
    return message.replaceFirst('Exception: ', '');
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 13)),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _pickAttachment(ImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1400,
    );
    if (image == null) return;

    setState(() {
      _attachment = File(image.path);
      _attachmentName = image.name;
    });
  }

  void _showAttachmentSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 14),
                _SourceTile(
                  icon: Icons.photo_camera_rounded,
                  title: 'Ambil Foto',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAttachment(ImageSource.camera);
                  },
                ),
                _SourceTile(
                  icon: Icons.photo_library_rounded,
                  title: 'Pilih dari Galeri',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAttachment(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _HeaderCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
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
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _CashSummaryCard extends StatelessWidget {
  final Map<String, dynamic> summary;

  const _CashSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _SummaryMetric(label: 'Limit', value: _money(summary['limit'])),
              _SummaryMetric(
                label: 'Aktif',
                value: _money(summary['active_outstanding']),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SummaryMetric(
                label: 'Pending',
                value: _money(summary['pending_amount']),
              ),
              _SummaryMetric(
                label: 'Sisa Limit',
                value: _money(summary['remaining_limit']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _money(dynamic value) {
    final amount = value is int
        ? value
        : int.tryParse(value?.toString() ?? '') ?? 0;
    return NumberFormat.compactCurrency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      decoration: _inputDecoration(label),
      borderRadius: BorderRadius.circular(14),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.onTap,
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
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: AppTheme.armyGreen,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    display,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool hasAttachment;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _AttachmentTile({
    required this.title,
    required this.subtitle,
    required this.hasAttachment,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.armyGreenLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.attach_file_rounded,
                color: AppTheme.armyGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (hasAttachment && onRemove != null)
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, color: AppTheme.error),
              )
            else
              const Icon(
                Icons.add_circle_outline_rounded,
                color: AppTheme.armyGreen,
              ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.armyGreenLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppTheme.armyGreen),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textDark,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppTheme.textMuted,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<_SummaryRow> rows;

  const _SummaryCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.label,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        row.value,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SummaryRow {
  final String label;
  final String value;

  const _SummaryRow(this.label, this.value);
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, color: Colors.white, size: 19),
        label: Text(
          isLoading ? 'Mengirim...' : label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.success,
          disabledBackgroundColor: AppTheme.success.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppTheme.textMuted),
    filled: true,
    fillColor: AppTheme.surfaceAlt,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppTheme.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppTheme.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppTheme.success, width: 1.4),
    ),
  );
}
