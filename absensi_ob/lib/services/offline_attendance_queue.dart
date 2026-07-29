import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_service.dart';

/// Offline-first attendance queue.
///
/// When the device has no internet, attendance records are stored locally.
/// When connectivity returns, [syncAll] sends them to the server.
/// Timestamps and GPS coordinates are captured at the time of attendance,
/// NOT at the time of sync — so the server always receives the original data.
class OfflineAttendanceQueue {
  OfflineAttendanceQueue._();

  static const _storage = FlutterSecureStorage();
  static const _queueKey = 'offline_attendance_queue';

  /// Add an attendance record to the offline queue.
  static Future<void> enqueue(Map<String, dynamic> data) async {
    final queue = await _loadQueue();
    queue.add(data);
    await _saveQueue(queue);
  }

  /// Get all pending (un-synced) attendance records.
  static Future<List<Map<String, dynamic>>> getPending() async {
    return _loadQueue();
  }

  /// Returns true if there are un-synced records.
  static Future<bool> hasPending() async {
    final queue = await _loadQueue();
    return queue.isNotEmpty;
  }

  /// Attempt to sync all queued records to the server.
  ///
  /// Successfully synced records are removed from the queue.
  /// Records that fail to sync (e.g. server error) remain in the queue.
  ///
  /// Returns the number of successfully synced records.
  static Future<int> syncAll() async {
    final queue = await _loadQueue();
    if (queue.isEmpty) return 0;

    final remaining = <Map<String, dynamic>>[];
    int synced = 0;

    for (final record in queue) {
      try {
        await ApiService.sendAttendance(record);
        synced++;
      } on ApiException catch (e) {
        // Jika bad request / conflict (400-499), buang dari antrian agar tidak stuck
        if (e.statusCode >= 400 && e.statusCode < 500) {
          continue;
        }
        // Selain itu (misal server error 500), simpan untuk coba lagi
        remaining.add(record);
      } catch (_) {
        // Kesalahan koneksi / timeout, simpan untuk coba lagi
        remaining.add(record);
      }
    }

    await _saveQueue(remaining);
    return synced;
  }

  /// Clear the entire queue (e.g. on logout).
  static Future<void> clear() async {
    await _storage.delete(key: _queueKey);
  }

  // ── Private ──────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> _loadQueue() async {
    final raw = await _storage.read(key: _queueKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveQueue(List<Map<String, dynamic>> queue) async {
    await _storage.write(key: _queueKey, value: jsonEncode(queue));
  }
}
