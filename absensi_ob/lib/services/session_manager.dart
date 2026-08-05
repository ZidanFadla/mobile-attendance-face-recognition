import '../models/attendance_record.dart';
import 'api_service.dart';

class SessionManager {
  static List<AttendanceRecord> _attendanceData = [];

  /// Ambil riwayat absensi user yang sedang login.
  static List<AttendanceRecord> getRecords(String name) {
    return List.unmodifiable(_attendanceData);
  }

  /// Tambah record baru untuk sesi user yang sedang login.
  static void addRecord(String name, AttendanceRecord record) {
    _attendanceData.add(record);
  }

  /// Ambil record hari ini berdasarkan tipe.
  static AttendanceRecord? getTodayRecord(String name, String type) {
    final now = DateTime.now();
    final normalizedType = _normalizeAttendanceType(type);

    for (final record in _attendanceData) {
      if (_normalizeAttendanceType(record.type) == normalizedType &&
          record.timestamp.year == now.year &&
          record.timestamp.month == now.month &&
          record.timestamp.day == now.day) {
        return record;
      }
    }
    return null;
  }

  /// Muat riwayat absensi dari database API lalu simpan ke memori lokal.
  static Future<bool> loadFromApi(String name) async {
    try {
      final list = await ApiService.fetchAttendanceHistory();
      final records = <AttendanceRecord>[];

      for (final item in list) {
        final timestamp = DateTime.parse(item['timestamp'] as String);
        records.add(
          AttendanceRecord(
            name: item['name']?.toString() ?? name,
            phoneNumber: item['phone']?.toString() ?? '',
            timestamp: timestamp.isUtc ? timestamp.toLocal() : timestamp,
            type: item['type']?.toString() ?? '',
            latitude: _toDouble(item['latitude']),
            longitude: _toDouble(item['longitude']),
            locationName: item['location_name']?.toString() ?? '',
          ),
        );
      }

      _attendanceData = records;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Bersihkan data saat logout / login user baru.
  static void clear() {
    _attendanceData = [];
  }

  static String _normalizeAttendanceType(String type) {
    final value = type.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (value == 'masuk' || value == 'clockin' || value == 'in') {
      return 'masuk';
    }
    if (value == 'pulang' ||
        value == 'keluar' ||
        value == 'clockout' ||
        value == 'out') {
      return 'pulang';
    }
    return value;
  }

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}
