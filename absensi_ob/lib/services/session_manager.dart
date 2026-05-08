import '../models/attendance_record.dart';

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

  /// Ambil record hari ini berdasarkan tipe
  static AttendanceRecord? getTodayRecord(String name, String type) {
    final records = _attendanceData[name] ?? [];
    final now = DateTime.now();

    for (final record in records) {
      if (record.type == type &&
          record.timestamp.year == now.year &&
          record.timestamp.month == now.month &&
          record.timestamp.day == now.day) {
        return record;
      }
    }
    return null;
  }
}
