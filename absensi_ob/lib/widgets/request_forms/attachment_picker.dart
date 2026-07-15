import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_theme.dart';
import 'attachment_camera_page.dart';
import 'request_form_widgets.dart';

/// Mixin to handle picking files (camera/gallery) with image_picker package.
/// Eliminates duplicate image picking boilerplate in LeaveRequestPage and CashAdvanceRequestPage.
mixin AttachmentPickerMixin<T extends StatefulWidget> on State<T> {
  final ImagePicker _imagePicker = ImagePicker();

  /// Prompts image picker with memory-friendly settings for low-end Android devices.
  Future<XFile?> pickAttachment(ImageSource source) async {
    try {
      return await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );
    } catch (e) {
      debugPrint('Attachment picker failed: $e');
      return null;
    }
  }

  /// Recovers image_picker results if Android killed the app while camera/gallery was open.
  Future<void> recoverLostAttachment({
    required void Function(File file, String name) onAttachmentPicked,
  }) async {
    try {
      final response = await _imagePicker.retrieveLostData();
      if (response.isEmpty || !mounted) return;

      final file = response.file ??
          (response.files?.isNotEmpty == true ? response.files!.first : null);
      if (file != null) {
        onAttachmentPicked(File(file.path), file.name);
      } else if (response.exception != null) {
        debugPrint('Attachment lost-data error: ${response.exception}');
      }
    } catch (e) {
      debugPrint('Attachment lost-data recovery failed: $e');
    }
  }

  /// Displays the attachment source bottom sheet with options to Take Photo or Choose from Gallery.
  void showAttachmentSourceSheet({
    required void Function(File file, String name) onAttachmentPicked,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
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
                RequestSourceTile(
                  icon: Icons.photo_camera_rounded,
                  title: 'Ambil Foto',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final path = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AttachmentCameraPage(),
                      ),
                    );
                    if (path != null && mounted) {
                      final file = File(path);
                      onAttachmentPicked(file, file.uri.pathSegments.last);
                    }
                  },
                ),
                RequestSourceTile(
                  icon: Icons.photo_library_rounded,
                  title: 'Pilih dari Galeri',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final image = await pickAttachment(ImageSource.gallery);
                    if (image != null && mounted) {
                      onAttachmentPicked(File(image.path), image.name);
                    }
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