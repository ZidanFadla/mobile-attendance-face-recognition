import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/request_forms/request_form_widgets.dart';
import 'request_history_page.dart';

class LeaveRequestPage extends StatefulWidget {
  const LeaveRequestPage({super.key});

  @override
  State<LeaveRequestPage> createState() => _LeaveRequestPageState();
}

class _LeaveRequestPageState extends State<LeaveRequestPage>
    with AttachmentPickerMixin<LeaveRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _contactController = TextEditingController();
  final _handoverController = TextEditingController();


  String _leaveType = 'Cuti Tahunan';
  DateTime? _startDate;
  DateTime? _endDate;
  File? _attachment;
  String? _attachmentName;
  Map<String, dynamic>? _leaveBalance;
  bool _halfDay = false;
  bool _isSubmitting = false;

  final _leaveTypes = const [
    'Cuti Tahunan',
    'Cuti Sakit',
    'Izin Pribadi',
    'Cuti Darurat',
    'Cuti Melahirkan',
  ];

  @override
  void initState() {
    super.initState();
    _loadLeaveBalance();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _contactController.dispose();
    _handoverController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaveBalance() async {
    try {
      final balance = await ApiService.fetchLeaveBalance();
      if (!mounted) return;
      setState(() => _leaveBalance = balance);
    } catch (_) {
      // Balance is helpful, but the form can still be filled.
    }
  }

  int get _durationDays {
    if (_startDate == null || _endDate == null) return 0;
    if (_halfDay) return 1;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startDate ?? now)
        : (_endDate ?? _startDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );

    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submitLeaveRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal mulai dan selesai cuti.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = await ApiService.submitLeaveRequest(
        leaveType: _leaveType,
        startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate!),
        isHalfDay: _halfDay,
        reason: _reasonController.text.trim(),
        contactDuringLeave: _contactController.nullableText,
        handoverNote: _handoverController.nullableText,
        attachment: _attachment,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (data['success'] == true) {
        _reasonController.clear();
        _contactController.clear();
        _handoverController.clear();
        setState(() {
          _startDate = null;
          _endDate = null;
          _attachment = null;
          _attachmentName = null;
          _halfDay = false;
        });
        _loadLeaveBalance();
        showSuccessSnackbar(context, data['message'] ?? 'Pengajuan cuti berhasil dikirim.');
      } else {
        showErrorSnackbar(
          context,
          data['message'] ?? 'Pengajuan cuti gagal dikirim.',
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
          'Pengajuan Cuti',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Riwayat cuti',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const RequestHistoryPage(type: RequestHistoryType.leave),
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
              icon: Icons.event_available_rounded,
              color: AppTheme.armyGreen,
              title: 'Form Cuti Karyawan',
              subtitle:
                  'Lengkapi data cuti agar admin dapat meninjau pengajuan dengan jelas.',
            ),
            if (_leaveBalance != null) ...[
              const SizedBox(height: 14),
              _LeaveBalanceCard(balance: _leaveBalance!),
            ],
            const SizedBox(height: 16),
            RequestSectionCard(
              title: 'Detail Cuti',
              children: [
                RequestDropdownField(
                  label: 'Jenis Cuti',
                  value: _leaveType,
                  items: _leaveTypes,
                  onChanged: (value) => setState(() => _leaveType = value),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: RequestDatePickerTile(
                        label: 'Mulai',
                        value: _startDate,
                        onTap: () => _pickDate(isStart: true),
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RequestDatePickerTile(
                        label: 'Selesai',
                        value: _endDate,
                        onTap: () => _pickDate(isStart: false),
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _halfDay,
                  onChanged: (value) => setState(() => _halfDay = value),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppTheme.armyGreen,
                  title: Text(
                    'Setengah hari',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  subtitle: Text(
                    'Aktifkan jika cuti hanya sebagian hari.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            RequestSectionCard(
              title: 'Keterangan',
              children: [
                RequestTextAreaField(
                  controller: _reasonController,
                  label: 'Alasan Cuti',
                  hint:
                      'Contoh: keperluan keluarga, sakit, urusan administrasi, dll.',
                  minLines: 4,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Alasan cuti wajib diisi'
                      : null,
                ),
                const SizedBox(height: 14),
                RequestTextAreaField(
                  controller: _contactController,
                  label: 'Kontak Selama Cuti',
                  hint: 'Nomor HP aktif atau kontak darurat.',
                  minLines: 2,
                ),
                const SizedBox(height: 14),
                RequestTextAreaField(
                  controller: _handoverController,
                  label: 'Serah Terima Tugas',
                  hint:
                      'Catatan pekerjaan/tugas yang perlu diketahui pengganti.',
                  minLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 14),
            RequestAttachmentTile(
              title: 'Lampiran Pendukung',
              subtitle:
                  _attachmentName ??
                  'Foto surat dokter atau dokumen pendukung.',
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
                SummaryRowData('Jenis', _leaveType),
                SummaryRowData(
                  'Durasi',
                  _durationDays == 0 ? '-' : '$_durationDays hari',
                ),
                SummaryRowData('Status Awal', 'Menunggu persetujuan admin'),
              ],
            ),
            const SizedBox(height: 18),
            RequestPrimaryButton(
              label: 'Ajukan Cuti',
              icon: Icons.send_rounded,
              isLoading: _isSubmitting,
              onPressed: _submitLeaveRequest,
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

class _LeaveBalanceCard extends StatelessWidget {
  final Map<String, dynamic> balance;

  const _LeaveBalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.armyGreenLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.armyGreen.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          _BalanceItem(label: 'Kuota', value: '${balance['quota'] ?? 0}'),
          _BalanceItem(
            label: 'Terpakai',
            value: '${balance['approved_used'] ?? 0}',
          ),
          _BalanceItem(label: 'Pending', value: '${balance['pending'] ?? 0}'),
          _BalanceItem(
            label: 'Tersedia',
            value: '${balance['available'] ?? 0}',
          ),
        ],
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final String label;
  final String value;

  const _BalanceItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
