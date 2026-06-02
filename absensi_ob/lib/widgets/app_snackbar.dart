import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Shared error snackbar — eliminates duplicated _showError across pages.
void showErrorSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
        ],
      ),
      backgroundColor: AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ),
  );
}

/// Shared success snackbar — eliminates duplicated _showSuccess across pages.
void showSuccessSnackbar(BuildContext context, String message) {
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

/// Utility: extract error message from Exception, stripping the "Exception: " prefix.
String cleanExceptionMessage(Object error) {
  return error.toString().replaceFirst('Exception: ', '');
}

/// Extension on TextEditingController untuk nullable text helper.
/// Mengembalikan null jika teks kosong atau hanya whitespace.
extension NullableTextController on TextEditingController {
  String? get nullableText {
    final value = text.trim();
    return value.isEmpty ? null : value;
  }
}
