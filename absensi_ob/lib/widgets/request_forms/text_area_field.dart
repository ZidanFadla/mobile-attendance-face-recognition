import 'package:flutter/material.dart';
import '../../core/form_decorations.dart';

/// Reusable multi-line text area untuk form request
class RequestTextAreaField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int minLines;
  final String? Function(String?)? validator;

  const RequestTextAreaField({
    super.key,
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
      decoration: buildInputDecoration(label).copyWith(hintText: hint),
    );
  }
}
