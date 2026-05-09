import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_colors.dart';

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

  String _leaveType = 'Cuti Tahunan';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _halfDay = false;

  final _leaveTypes = const [
    'Cuti Tahunan',
    'Cuti Sakit',
    'Izin Pribadi',
    'Cuti Darurat',
    'Cuti Melahirkan',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    _contactController.dispose();
    _handoverController.dispose();
    super.dispose();
  }

  int get _durationDays {
    if (_startDate == null || _endDate == null) return 0;
    if (_halfDay) return 1;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? (_startDate ?? now) : (_endDate ?? _startDate ?? now);
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

  void _submitPreview() {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal mulai dan selesai cuti.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('UI pengajuan cuti sudah siap. API akan dibuat tahap berikutnya.'),
      ),
    );
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
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800),
        ),
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
              subtitle: 'Lengkapi data cuti agar admin dapat meninjau pengajuan dengan jelas.',
            ),
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
                  activeColor: AppColors.primary,
                  title: const Text(
                    'Setengah hari',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
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
                  hint: 'Contoh: keperluan keluarga, sakit, urusan administrasi, dll.',
                  minLines: 4,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Alasan cuti wajib diisi' : null,
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
                  hint: 'Catatan pekerjaan/tugas yang perlu diketahui pengganti.',
                  minLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _AttachmentTile(
              title: 'Lampiran Pendukung',
              subtitle: 'Surat dokter atau dokumen pendukung lain.',
              onTap: () => _showComingSoon('Upload lampiran'),
            ),
            const SizedBox(height: 14),
            _SummaryCard(
              rows: [
                _SummaryRow('Jenis', _leaveType),
                _SummaryRow('Durasi', _durationDays == 0 ? '-' : '$_durationDays hari'),
                _SummaryRow('Status Awal', 'Menunggu persetujuan admin'),
              ],
            ),
            const SizedBox(height: 18),
            _PrimaryButton(
              label: 'Ajukan Cuti',
              icon: Icons.send_rounded,
              onPressed: _submitPreview,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label akan dibuat saat tahap fungsional.')),
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
      value: value,
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
    final display = value == null ? 'Pilih tanggal' : DateFormat('dd MMM yyyy').format(value!);

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
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 7),
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 17, color: AppColors.primary),
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
  final VoidCallback onTap;

  const _AttachmentTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
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
              child: const Icon(Icons.attach_file_rounded, color: AppColors.primary),
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
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
          ],
        ),
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
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
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
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 19),
        label: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
