import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../core/form_decorations.dart';
import '../services/api_service.dart';
import '../widgets/app_snackbar.dart'; // showSuccessSnackbar, cleanExceptionMessage, NullableTextController
import '../widgets/request_forms/request_form_widgets.dart';
import 'request_history_page.dart';

class CashAdvanceRequestPage extends StatefulWidget {
  const CashAdvanceRequestPage({super.key});

  @override
  State<CashAdvanceRequestPage> createState() => _CashAdvanceRequestPageState();
}

class _CashAdvanceRequestPageState extends State<CashAdvanceRequestPage>
    with AttachmentPickerMixin<CashAdvanceRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _bankController = TextEditingController();
  final _accountController = TextEditingController();

  String _purpose = 'Kebutuhan Medis';
  String _repayment = 'Potong Gaji 1x';
  DateTime? _neededDate;
  File? _attachment;
  String? _attachmentName;
  Map<String, dynamic>? _cashSummary;
  bool _isSubmitting = false;

  final _purposes = const [
    'Kebutuhan Medis',
    'Pendidikan Anak',
    'Perbaikan Rumah',
    'Kendaraan Bermotor',
    'Keperluan Darurat',
    'Lainnya',
  ];

  final _repayments = const [
    'Potong Gaji 1x',
    'Potong Gaji 2x',
    'Potong Gaji 3x',
    'Transfer Mandiri',
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
      // Summary is helpful, but the form can still be filled.
    }
  }

  int get _amount => int.tryParse(_amountController.text) ?? 0;

  Future<void> _pickNeededDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _neededDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );

    if (picked == null) return;
    setState(() => _neededDate = picked);
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
        neededDate: DateFormat('yyyy-MM-dd').format(_neededDate!),
        purpose: _purpose,
        repaymentMethod: _repayment,
        reason: _reasonController.text.trim(),
        disbursementMethod: _bankController.nullableText ?? 'Cash',
        accountNumber: _accountController.nullableText,
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
        showSuccessSnackbar(
          context,
          data['message'] ?? 'Pengajuan kasbon berhasil dikirim.',
        );
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
      _handleSubmitError(cleanExceptionMessage(e));
    }
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
            RequestHeaderCard(
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
            RequestSectionCard(
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
                  decoration: buildInputDecoration(
                    'Nominal Kasbon',
                  ).copyWith(prefixText: 'Rp ', hintText: '500000'),
                ),
                const SizedBox(height: 14),
                RequestDropdownField(
                  label: 'Tujuan Pengajuan',
                  value: _purpose,
                  items: _purposes,
                  onChanged: (value) => setState(() => _purpose = value),
                ),
                const SizedBox(height: 14),
                RequestDatePickerTile(
                  label: 'Tanggal Dana Dibutuhkan',
                  value: _neededDate,
                  onTap: _pickNeededDate,
                ),
              ],
            ),
            const SizedBox(height: 14),
            RequestSectionCard(
              title: 'Rencana Pengembalian',
              children: [
                RequestDropdownField(
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
                  decoration: buildInputDecoration('Alasan Pengajuan').copyWith(
                    hintText:
                        'Jelaskan kebutuhan kasbon secara singkat dan jelas.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            RequestSectionCard(
              title: 'Informasi Pencairan',
              children: [
                TextFormField(
                  controller: _bankController,
                  decoration: buildInputDecoration(
                    'Nama Bank / Metode',
                  ).copyWith(hintText: 'Contoh: BCA, BRI, Mandiri, Cash'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _accountController,
                  keyboardType: TextInputType.number,
                  decoration: buildInputDecoration(
                    'Nomor Rekening',
                  ).copyWith(hintText: 'Opsional jika pencairan cash'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            RequestAttachmentTile(
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
            RequestSummaryCard(
              rows: [
                SummaryRowData(
                  'Nominal',
                  _amount == 0
                      ? '-'
                      : NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(_amount),
                ),
                SummaryRowData('Tujuan', _purpose),
                SummaryRowData('Pengembalian', _repayment),
                SummaryRowData('Status Awal', 'Menunggu persetujuan admin'),
              ],
            ),
            const SizedBox(height: 18),
            RequestPrimaryButton(
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

  void _handleSubmitError(String message) {
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    showErrorSnackbar(context, message);
  }

  void _showAttachmentSourceSheet() {
    showAttachmentSourceSheet(
      onAttachmentPicked: (file, name) {
        setState(() {
          _attachment = file;
          _attachmentName = name;
        });
      },
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
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
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
