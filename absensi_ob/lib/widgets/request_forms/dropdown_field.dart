import 'package:flutter/material.dart';
import '../../core/form_decorations.dart';

/// Reusable dropdown field untuk form request (Leave & Cash Advance)
class RequestDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const RequestDropdownField({
    super.key,
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
      decoration: buildInputDecoration(label),
      borderRadius: BorderRadius.circular(14),
    );
  }
}
