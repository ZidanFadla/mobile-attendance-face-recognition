import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

/// Reusable attachment tile untuk upload file/image
class RequestAttachmentTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool hasAttachment;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const RequestAttachmentTile({
    super.key,
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
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasAttachment
                ? AppTheme.success.withValues(alpha: 0.3)
                : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hasAttachment
                    ? AppTheme.success.withValues(alpha: 0.1)
                    : AppTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                hasAttachment
                    ? Icons.check_circle_rounded
                    : Icons.attach_file_rounded,
                color: hasAttachment ? AppTheme.success : AppTheme.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (hasAttachment && onRemove != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onRemove,
                icon: Icon(
                  Icons.close_rounded,
                  color: AppTheme.error,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.error.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
