import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../core/app_constants.dart';
import '../services/api_service.dart';
import '../services/face_api_service.dart';
import '../services/location_service.dart';
import '../services/session_manager.dart';

/// Result returned from attendance operations.
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

/// Holds all attendance business logic.
/// Uses [ChangeNotifier] so the UI rebuilds automatically via [addListener].
class AttendanceController extends ChangeNotifier {
  final String name;
  final String phoneNumber;

  bool _disposed = false;

  // State
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
  DateTime? timestampMasuk;
  DateTime? timestampPulang;

  AttendanceController({required this.name, required this.phoneNumber});

  /// Called once in HomePage.initState().
  /// Returns true if the employee hasn't registered their face yet.
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
    if (kDebugMode && AppConstants.devAttendanceBypass) {
      isFaceRegistered = true;
      isCheckingFace = false;
      notifyListeners();
      return false;
    }

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

  // ── Clock In & Out ──

  Future<AttendanceResult> clockIn(File photo) =>
      _processAttendance(photo, 'Masuk');

  Future<AttendanceResult> clockOut(File photo) =>
      _processAttendance(photo, 'Pulang');

  /// Unified implementation for both clock in and clock out.
  Future<AttendanceResult> _processAttendance(
    File photoFile,
    String type,
  ) async {
    try {
      _setLoading(true, '🔍 Memverifikasi wajah...\nMohon tunggu sebentar');
      final faceResult = await FaceApiService.verifyFace(
        filePath: photoFile.path,
        isVideo: false,
      );

      if (!faceResult.success || faceResult.match != true) {
        _setLoading(false);
        return AttendanceResult(success: false, message: faceResult.message);
      }

      _setLoading(true, '📍 Mengambil lokasi...');
      final position = await LocationService.getCurrentLocation();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final place = placemarks[0];
      final locationName =
          '${place.street}, ${place.subLocality}, ${place.locality}';

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

      if (type == 'Masuk') {
        isClockedIn = true;
        clockInTime = formattedTime;
        photoMasuk = photoFile;
        latitudeMasuk = position.latitude;
        longitudeMasuk = position.longitude;
        alamatMasuk = locationName;
        timestampMasuk = now;
      } else {
        clockOutTime = formattedTime;
        photoPulang = photoFile;
        latitudePulang = position.latitude;
        longitudePulang = position.longitude;
        alamatPulang = locationName;
        timestampPulang = now;
      }

      _setLoading(false);

      return AttendanceResult(
        success: true,
        message:
            '✅ Absen $type berhasil!\nJam: $formattedTime\nWajah terverifikasi (${faceResult.confidence?.toStringAsFixed(1) ?? '99'}%)',
        time: formattedTime,
      );
    } on TimeoutException {
      _setLoading(false);
      return const AttendanceResult(
        success: false,
        message:
            '⏱️ Server tidak merespons.\nPastikan terhubung ke jaringan yang benar dan coba lagi.',
      );
    } on Exception catch (e) {
      _setLoading(false);
      return AttendanceResult(
        success: false,
        message:
            'Terjadi kesalahan:\n${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  // ── Register Face ──

  Future<AttendanceResult> registerFace(List<File> photos) async {
    try {
      if (kDebugMode && AppConstants.devAttendanceBypass) {
        isFaceRegistered = true;
        notifyListeners();
        return const AttendanceResult(
          success: true,
          message: 'Mode emulator: registrasi wajah dilewati.',
        );
      }

      _setLoading(
        true,
        '🧠 Memproses data wajah...\nIni mungkin memerlukan beberapa detik',
      );

      final regResult = await FaceApiService.registerFace(
        photos.map((f) => f.path).toList(),
      );

      _setLoading(false);

      if (regResult.success) {
        isFaceRegistered = true;
        notifyListeners();
      }

      return AttendanceResult(
        success: regResult.success,
        message: regResult.message,
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
        message:
            'Gagal registrasi:\n${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  void _setLoading(bool loading, [String message = '']) {
    isLoading = loading;
    loadingMessage = message;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
