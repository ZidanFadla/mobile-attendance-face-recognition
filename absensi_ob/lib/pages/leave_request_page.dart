import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../core/app_colors.dart';
import '../services/api_service.dart';
import '../widgets/app_snackbar.dart';
import 'request_history_page.dart';

class LeaveRequestPage extends StatefulWidget {
  const LeaveRequestPage({super.key});

  @override
  State<LeaveRequestPage> createState() => _LeaveRequestPageState();
}

class _LeaveRequestPageState extends State<LeaveRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _contactController = TextEditingController();
  final _handoverController = TextEditingController();
  final _imagePicker = ImagePicker();

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
        contactDuringLeave: _nullableText(_contactController),
        handoverNote: _nullableText(_handoverController),
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
        _showSuccess(data['message'] ?? 'Pengajuan cuti berhasil dikirim.');
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
      _handleSubmitError(_cleanError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: const Text(
          'Pengajuan Cuti',
          style: TextStyle(
            color: AppColors.textDark,
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
            const _HeaderCard(
              icon: Icons.event_available_rounded,
              color: AppColors.primary,
              title: 'Form Cuti Karyawan',
              subtitle:
                  'Lengkapi data cuti agar admin dapat meninjau pengajuan dengan jelas.',
            ),
            if (_leaveBalance != null) ...[
              const SizedBox(height: 14),
              _LeaveBalanceCard(balance: _leaveBalance!),
            ],
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Detail Cuti',
              children: [
                _DropdownField(
                  label: 'Jenis Cuti',
                  value: _leaveType,
                  items: _leaveTypes,
                  onChanged: (value) => setState(() => _leaveType = value),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _DatePickerTile(
                        label: 'Mulai',
                        value: _startDate,
                        onTap: () => _pickDate(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DatePickerTile(
                        label: 'Selesai',
                        value: _endDate,
                        onTap: () => _pickDate(isStart: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _halfDay,
                  onChanged: (value) => setState(() => _halfDay = value),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.primary,
                  title: const Text(
                    'Setengah hari',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  subtitle: const Text(
                    'Aktifkan jika cuti hanya sebagian hari.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Keterangan',
              children: [
                _TextAreaField(
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
                _TextAreaField(
                  controller: _contactController,
                  label: 'Kontak Selama Cuti',
                  hint: 'Nomor HP aktif atau kontak darurat.',
                  minLines: 2,
                ),
                const SizedBox(height: 14),
                _TextAreaField(
                  controller: _handoverController,
                  label: 'Serah Terima Tugas',
                  hint:
                      'Catatan pekerjaan/tugas yang perlu diketahui pengganti.',
                  minLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _AttachmentTile(
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
            _SummaryCard(
              rows: [
                _SummaryRow('Jenis', _leaveType),
                _SummaryRow(
                  'Durasi',
                  _durationDays == 0 ? '-' : '$_durationDays hari',
                ),
                _SummaryRow('Status Awal', 'Menunggu persetujuan admin'),
              ],
            ),
            const SizedBox(height: 18),
            _PrimaryButton(
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
        backgroundColor: AppColors.success,
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
      backgroundColor: AppColors.surface,
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
                    color: AppColors.border,
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
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
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

class _LeaveBalanceCard extends StatelessWidget {
  final Map<String, dynamic> balance;

  const _LeaveBalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
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
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
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
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 17,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    display,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TextAreaField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int minLines;
  final String? Function(String?)? validator;

  const _TextAreaField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.minLines,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: minLines + 2,
      validator: validator,
      decoration: _inputDecoration(label).copyWith(hintText: hint),
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.attach_file_rounded,
                color: AppColors.primary,
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
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (hasAttachment && onRemove != null)
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, color: AppColors.error),
              )
            else
              const Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.primary,
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
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
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
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
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
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      row.value,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
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
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.55),
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
    labelStyle: const TextStyle(color: AppColors.textMuted),
    filled: true,
    fillColor: AppColors.bg,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
    ),
  );
}
