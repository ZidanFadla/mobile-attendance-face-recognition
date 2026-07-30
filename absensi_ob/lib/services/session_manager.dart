import '../models/attendance_record.dart';
import 'api_service.dart';

class SessionManager {
  static final Map<String, List<AttendanceRecord>> _attendanceData = {};

  /// Ambil riwayat berdasarkan nama
  static List<AttendanceRecord> getRecords(String name) {
    return _attendanceData[name] ?? [];
  }

  /// Tambah record baru
  static void addRecord(String name, AttendanceRecord record) {
    _attendanceData.putIfAbsent(name, () => []).add(record);
  }

  /// Ambil record hari ini berdasarkan tipe.
  static AttendanceRecord? getTodayRecord(String name, String type) {
    final records = _attendanceData[name] ?? [];
    final now = DateTime.now();
    final normalizedType = _normalizeAttendanceType(type);

    for (final record in records) {
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
  /// Dipanggil sekali saat login / MainShell dimuat.
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

      _attendanceData[name] = records;
      return true;
    } catch (_) {
      // Jika gagal fetch, biarkan data tetap kosong / data sesi sebelumnya
      return false;
    }
  }

  /// Bersihkan data saat logout
  static void clear() {
    _attendanceData.clear();
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
