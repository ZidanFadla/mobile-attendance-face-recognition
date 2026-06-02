import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_theme.dart';
import 'request_form_widgets.dart';

/// Mixin to handle picking files (camera/gallery) with image_picker package.
/// Eliminates duplicate image picking boilerplate in LeaveRequestPage and CashAdvanceRequestPage.
mixin AttachmentPickerMixin<T extends StatefulWidget> on State<T> {
  final ImagePicker _imagePicker = ImagePicker();

  /// Prompts image picker with specific settings (quality 82, max width 1400)
  Future<XFile?> pickAttachment(ImageSource source) async {
    return await _imagePicker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1400,
    );
  }

  /// Displays the attachment source bottom sheet with options to Take Photo or Choose from Gallery.
  void showAttachmentSourceSheet({
    required Function(File file, String name) onAttachmentPicked,
  }) {
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
                RequestSourceTile(
                  icon: Icons.photo_camera_rounded,
                  title: 'Ambil Foto',
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await pickAttachment(ImageSource.camera);
                    if (image != null) {
                      onAttachmentPicked(File(image.path), image.name);
                    }
                  },
                ),
                RequestSourceTile(
                  icon: Icons.photo_library_rounded,
                  title: 'Pilih dari Galeri',
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await pickAttachment(ImageSource.gallery);
                    if (image != null) {
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
