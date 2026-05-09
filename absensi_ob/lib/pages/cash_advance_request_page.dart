import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/app_colors.dart';

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

  String _purpose = 'Kebutuhan Mendesak';
  String _repayment = 'Potong Gaji Bulan Ini';
  DateTime? _neededDate;

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
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _bankController.dispose();
    _accountController.dispose();
    super.dispose();
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

  void _submitPreview() {
    if (!_formKey.currentState!.validate()) return;
    if (_neededDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal dana dibutuhkan.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('UI pengajuan kasbon sudah siap. API akan dibuat tahap berikutnya.'),
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
          'Pengajuan Kasbon',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _HeaderCard(
              icon: Icons.payments_rounded,
              color: Color(0xFF10B981),
              title: 'Form Kasbon Karyawan',
              subtitle: 'Ajukan dana sementara dengan alasan, tanggal kebutuhan, dan rencana pengembalian.',
            ),
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
                  decoration: _inputDecoration('Nominal Kasbon').copyWith(
                    prefixText: 'Rp ',
                    hintText: '500000',
                  ),
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
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Alasan kasbon wajib diisi' : null,
                  decoration: _inputDecoration('Alasan Pengajuan').copyWith(
                    hintText: 'Jelaskan kebutuhan kasbon secara singkat dan jelas.',
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
                  decoration: _inputDecoration('Nama Bank / Metode').copyWith(
                    hintText: 'Contoh: BCA, BRI, Mandiri, Cash',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _accountController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Nomor Rekening').copyWith(
                    hintText: 'Opsional jika pencairan cash',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _AttachmentTile(
              title: 'Lampiran Pendukung',
              subtitle: 'Bukti kebutuhan jika diperlukan.',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Upload lampiran akan dibuat saat tahap fungsional.')),
                );
              },
            ),
            const SizedBox(height: 14),
            _SummaryCard(
              rows: [
                _SummaryRow('Nominal', _amount == 0 ? '-' : NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_amount)),
                _SummaryRow('Tujuan', _purpose),
                _SummaryRow('Pengembalian', _repayment),
                _SummaryRow('Status Awal', 'Menunggu persetujuan admin'),
              ],
            ),
            const SizedBox(height: 18),
            _PrimaryButton(
              label: 'Ajukan Kasbon',
              icon: Icons.send_rounded,
              onPressed: _submitPreview,
            ),
          ],
        ),
      ),
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
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    display,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textDark,
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
        color: const Color(0xFFEFFDF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.16)),
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
                    Flexible(
                      child: Text(
                        row.value,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: AppColors.textDark,
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
          backgroundColor: AppColors.success,
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
      borderSide: const BorderSide(color: AppColors.success, width: 1.4),
    ),
  );
}
