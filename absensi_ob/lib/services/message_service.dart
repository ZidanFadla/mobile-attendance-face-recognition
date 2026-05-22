import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';
import 'token_storage.dart';

/// Service untuk polling pesan dari admin.
/// Polling interval: 10 detik.
class MessageService {
  MessageService._();

  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  static Timer? _pollingTimer;
  static Function(List<Map<String, dynamic>>)? _onNewMessages;
  static Function(int)? _onUnreadCount;
  static int _lastKnownCount = 0;

  /// Mulai polling pesan
  static void startPolling({
    required Function(List<Map<String, dynamic>>) onMessages,
    required Function(int) onUnreadCount,
    Duration interval = const Duration(seconds: 10),
  }) {
    _onNewMessages = onMessages;
    _onUnreadCount = onUnreadCount;
    _pollingTimer?.cancel();

    // Fetch langsung pertama kali
    fetchMessages();

    // Kemudian polling setiap interval
    _pollingTimer = Timer.periodic(interval, (_) => fetchMessages());
  }

  /// Stop polling
  static void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Fetch pesan dari API
  static Future<List<Map<String, dynamic>>> fetchMessages() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null || token.isEmpty) return [];

      final response = await http
          .get(
            Uri.parse('${AppConstants.baseUrl}/messages'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final messages = List<Map<String, dynamic>>.from(data['data'] ?? []);
          final unread = data['unread'] as int? ?? 0;

          unreadCountNotifier.value = unread;
          _onNewMessages?.call(messages);

          // Notify only if unread count changed
          if (unread != _lastKnownCount) {
            _lastKnownCount = unread;
            _onUnreadCount?.call(unread);
          }
          return messages;
        }
      }
    } catch (_) {
      // Silently ignore polling errors
    }
    return [];
  }

  /// Tandai satu pesan sebagai dibaca
  static Future<void> markRead(int id) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null || token.isEmpty) return;

      await http
          .post(
            Uri.parse('${AppConstants.baseUrl}/messages/$id/read'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      await fetchMessages();
    } catch (_) {
      // Silently ignore
    }
  }

  /// Tandai semua pesan sebagai dibaca
  static Future<void> markAllRead() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null || token.isEmpty) return;

      await http
          .post(
            Uri.parse('${AppConstants.baseUrl}/messages/read'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      _lastKnownCount = 0;
      unreadCountNotifier.value = 0;
      _onUnreadCount?.call(0);
    } catch (_) {
      // Silently ignore
    }
  }
}
