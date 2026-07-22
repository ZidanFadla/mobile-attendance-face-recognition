import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import '../services/message_service.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    MessageService.startPolling(
      onMessages: (messages) {
        if (mounted) {
          setState(() {
            _messages = messages;
            _loading = false;
          });
        }
      },
      onUnreadCount: (_) {},
      interval: const Duration(seconds: 10),
    );
  }

  @override
  void dispose() {
    MessageService.stopPolling();
    super.dispose();
  }

  IconData _typeIcon(String type) => switch (type) {
    'image' => Icons.image_rounded,
    'mixed' => Icons.perm_media_rounded,
    'file' => Icons.attach_file_rounded,
    _ => Icons.mail_rounded,
  };

  Color _typeColor(String type) => switch (type) {
    'image' || 'mixed' => AppTheme.warning,
    'file' => AppTheme.info,
    _ => AppTheme.armyGreen,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 1,
        title: Text(
          'Pesan',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.armyGreen))
          : _messages.isEmpty
          ? _emptyState()
          : RefreshIndicator(
              color: AppTheme.armyGreen,
              onRefresh: () async {
                final messages = await MessageService.fetchMessages();
                if (!mounted) return;
                setState(() => _messages = messages);
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _messageCard(_messages[i]),
              ),
            ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 36,
              color: AppTheme.textMuted.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada pesan',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pesan dari admin akan muncul di sini',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _messageCard(Map<String, dynamic> msg) {
    final type = msg['type']?.toString() ?? 'text';
    final content = msg['content']?.toString() ?? '';
    final imageUrl = msg['image_url']?.toString();
    final imageName = msg['image_name']?.toString() ?? 'Foto';
    final fileUrl = msg['file_url']?.toString();
    final fileName = msg['file_name']?.toString() ?? 'File';
    final sender = msg['sender']?.toString() ?? 'Admin';
    final sentAt = _formatDateTime(msg['created_at']?.toString());
    final timeAgo = msg['time_ago']?.toString() ?? sentAt;
    final isRead = msg['is_read'] == true;
    final preview = content.isEmpty
        ? (imageUrl != null
              ? imageName
              : (fileUrl != null ? fileName : 'Pesan tanpa isi'))
        : content;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openMessage(msg),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? AppTheme.border
                : AppTheme.armyGreen.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.isDark
                  ? Colors.black.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _typeColor(type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon(type), color: _typeColor(type), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          sender,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _typeColor(type).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            type.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _typeColor(type),
                            ),
                          ),
                        ),
                        if (!isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: AppTheme.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.textDark,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (imageUrl != null && imageUrl.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _openImagePreview(imageUrl, imageName),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 110,
                                  color: AppTheme.surfaceAlt,
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Foto tidak bisa dimuat',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ],
                    if (fileUrl != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _openFile(fileUrl),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceAlt,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                type == 'image'
                                    ? Icons.image_rounded
                                    : Icons.download_rounded,
                                size: 16,
                                color: AppTheme.armyGreen,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  fileName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.armyGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '$sentAt - $timeAgo',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openMessage(Map<String, dynamic> msg) async {
    final id = msg['id'];
    if (id is int && msg['is_read'] != true) {
      await MessageService.markRead(id);
    }
    if (!mounted) return;

    final type = msg['type']?.toString() ?? 'text';
    final content = msg['content']?.toString() ?? '';
    final imageUrl = msg['image_url']?.toString();
    final imageName = msg['image_name']?.toString() ?? 'Foto';
    final fileUrl = msg['file_url']?.toString();
    final fileName = msg['file_name']?.toString() ?? 'File';
    final sender = msg['sender']?.toString() ?? 'Admin';
    final sentAt = _formatDateTime(msg['created_at']?.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (context, controller) {
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _typeColor(type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(_typeIcon(type), color: _typeColor(type)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sender,
                            style: TextStyle(
                              color: AppTheme.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            sentAt,
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (content.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Text(
                    content,
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
                ],
                if (imageUrl != null && imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Text(
                    imageName,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _openImagePreview(imageUrl, imageName),
                    borderRadius: BorderRadius.circular(14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 180,
                          color: AppTheme.surfaceAlt,
                          alignment: Alignment.center,
                          child: Text(
                            'Foto tidak bisa dimuat',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (fileUrl != null && fileUrl.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  InkWell(
                    onTap: () => _openFile(fileUrl),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            type == 'image'
                                ? Icons.image_rounded
                                : Icons.attach_file_rounded,
                            color: AppTheme.armyGreen,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              fileName,
                              style: TextStyle(
                                color: AppTheme.armyGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.open_in_new_rounded,
                            color: AppTheme.textMuted,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) return raw;
    return DateFormat('dd MMM yyyy, HH:mm').format(parsed.toLocal());
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tidak bisa membuka file atau foto.')),
    );
  }

  void _openImagePreview(String url, String title) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (context) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _openFile(url),
                        icon: const Icon(
                          Icons.open_in_new_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: InteractiveViewer(
                    minScale: 0.7,
                    maxScale: 4,
                    child: Center(
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Text(
                              'Foto tidak bisa dimuat',
                              style: TextStyle(color: Colors.white70),
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
