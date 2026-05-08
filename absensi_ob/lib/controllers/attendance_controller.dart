import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../services/api_service.dart';
import '../services/face_recognition_service.dart';
import '../services/location_service.dart';
import '../services/session_manager.dart';

/// Hasil operasi absensi — digunakan untuk komunikasi antara
/// controller dan UI tanpa UI harus tahu detail prosesnya.
class AttendanceResult {
  final bool success;
  final String message;
  final String? time;

  const AttendanceResult({
    required this.success,
    required this.message,
    this.time,
  });
}

/// AttendanceController menyimpan SEMUA logika bisnis absensi.
/// Menggunakan [ChangeNotifier] sehingga UI rebuild otomatis via [addListener].
class AttendanceController extends ChangeNotifier {
  // ─── Info User ──────────────────────────────────────────────
  final String name;
  final String phoneNumber;

  // ─── State ──────────────────────────────────────────────────
  bool isClockedIn = false;
  bool isFaceRegistered = false;
  bool isCheckingFace = true;
  bool isLoading = false;

  String clockInTime = '--:--';
  String clockOutTime = '--:--';
  String loadingMessage = '';

  File? photoMasuk;
  File? photoPulang;
  double? latitudeMasuk;
  double? longitudeMasuk;
  double? latitudePulang;
  double? longitudePulang;
  String? alamatMasuk;
  String? alamatPulang;

  // ✅ Timestamp disimpan di controller — bukan DateTime.now() di build()
  DateTime? timestampMasuk;
  DateTime? timestampPulang;

  AttendanceController({required this.name, required this.phoneNumber});

  // ─── Init ────────────────────────────────────────────────────

  /// Dipanggil sekali saat HomePage.initState().
  /// Return true jika karyawan belum registrasi wajah.
  Future<bool> init() async {
    _loadTodayStatus();
    return await _fetchFaceRegistrationStatus();
  }

  void _loadTodayStatus() {
    final masukRecord = SessionManager.getTodayRecord(name, 'Masuk');
    final pulangRecord = SessionManager.getTodayRecord(name, 'Pulang');

    if (masukRecord != null) {
      isClockedIn = true;
      clockInTime = DateFormat('HH:mm').format(masukRecord.timestamp);
      timestampMasuk = masukRecord.timestamp;
    }
    if (pulangRecord != null) {
      clockOutTime = DateFormat('HH:mm').format(pulangRecord.timestamp);
      timestampPulang = pulangRecord.timestamp;
    }
    notifyListeners();
  }

  Future<bool> _fetchFaceRegistrationStatus() async {
    try {
      isFaceRegistered = await ApiService.checkFaceRegistration();
    } catch (_) {
      isFaceRegistered = false;
    } finally {
      isCheckingFace = false;
      notifyListeners();
    }
    return !isFaceRegistered;
  }

  // ─── Clock In & Out ─────────────────────────────────────────

  /// Absen masuk — delegasi ke _processAttendance.
  Future<AttendanceResult> clockIn(File photo) =>
      _processAttendance(photo, 'Masuk');

  /// Absen pulang — delegasi ke _processAttendance.
  Future<AttendanceResult> clockOut(File photo) =>
      _processAttendance(photo, 'Pulang');

  /// ✅ Satu implementasi untuk clock in DAN clock out.
  /// Sebelumnya ada 140 baris duplikasi — sekarang dikompres menjadi satu method.
  Future<AttendanceResult> _processAttendance(
    File photoFile,
    String type,
  ) async {
    try {
      // 1. Verifikasi wajah
      _setLoading(true, '🔍 Memverifikasi wajah...\nMohon tunggu sebentar');
      final faceResult = await FaceRecognitionService.verifyFace(
        imageFile: photoFile,
        userId: phoneNumber,
      );

      if (!faceResult['success'] || !faceResult['match']) {
        _setLoading(false);
        return AttendanceResult(
          success: false,
          message: faceResult['message'] ??
              'Wajah tidak cocok (${faceResult['confidence']}%).\nSilakan ulangi.',
        );
      }

      // 2. Ambil lokasi
      _setLoading(true, '📍 Mengambil lokasi...');
      final position = await LocationService.getCurrentLocation();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final place = placemarks[0];
      final locationName =
          '${place.street}, ${place.subLocality}, ${place.locality}';

      // 3. Simpan ke server & local session
      _setLoading(true, '💾 Menyimpan data absensi...');
      final now = DateTime.now();
      final formattedTime = DateFormat('HH:mm').format(now);

      final record = AttendanceRecord(
        name: name,
        phoneNumber: phoneNumber,
        timestamp: now,
        type: type,
        latitude: position.latitude,
        longitude: position.longitude,
        locationName: locationName,
      );

      await ApiService.sendAttendance({
        'type': type,
        'timestamp': now.toIso8601String(),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'location_name': locationName,
      });

      SessionManager.addRecord(name, record);

      // 4. Update state berdasarkan tipe
      if (type == 'Masuk') {
        isClockedIn = true;
        clockInTime = formattedTime;
        photoMasuk = photoFile;
        latitudeMasuk = position.latitude;
        longitudeMasuk = position.longitude;
        alamatMasuk = locationName;
        timestampMasuk = now; // ✅ simpan timestamp yang benar
      } else {
        clockOutTime = formattedTime;
        photoPulang = photoFile;
        latitudePulang = position.latitude;
        longitudePulang = position.longitude;
        alamatPulang = locationName;
        timestampPulang = now; // ✅ simpan timestamp yang benar
      }

      _setLoading(false);

      return AttendanceResult(
        success: true,
        message:
            '✅ Absen $type berhasil!\nJam: $formattedTime\nWajah terverifikasi (${faceResult['confidence']}%)',
        time: formattedTime,
      );
    } on TimeoutException {
      // ✅ Handle timeout request HTTP
      _setLoading(false);
      return const AttendanceResult(
        success: false,
        message:
            '⏱️ Server tidak merespons.\nPastikan terhubung ke jaringan yang benar dan coba lagi.',
      );
    } on Exception catch (e) {
      // ✅ Handle semua error lainnya (GPS mati, jaringan putus, dll)
      _setLoading(false);
      return AttendanceResult(
        success: false,
        message: 'Terjadi kesalahan:\n${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  // ─── Register Face ───────────────────────────────────────────

  Future<AttendanceResult> registerFace(List<File> photos) async {
    try {
      _setLoading(
        true,
        '🧠 Memproses data wajah...\nIni mungkin memerlukan beberapa detik',
      );

      final regResult = await FaceRecognitionService.registerFaceMultiple(
        imageFiles: photos,
        userId: phoneNumber,
        userName: name,
      );

      _setLoading(false);

      if (regResult['success'] == true) {
        isFaceRegistered = true;
        notifyListeners();
      }

      return AttendanceResult(
        success: regResult['success'] == true,
        message: regResult['message'] ?? 'Registrasi selesai',
      );
    } on TimeoutException {
      _setLoading(false);
      return const AttendanceResult(
        success: false,
        message: '⏱️ Server tidak merespons. Coba lagi.',
      );
    } on Exception catch (e) {
      _setLoading(false);
      return AttendanceResult(
        success: false,
        message: 'Gagal registrasi:\n${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  // ─── Helper ──────────────────────────────────────────────────

  void _setLoading(bool loading, [String message = '']) {
    isLoading = loading;
    loadingMessage = message;
    notifyListeners();
  }
}
