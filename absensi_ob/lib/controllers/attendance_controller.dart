import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../core/app_constants.dart';
import '../services/api_service.dart';
import '../services/face_api_service.dart';
import '../services/face_recognition_service.dart';
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
  bool isAttendanceReady = false;
  bool attendanceSyncFailed = false;
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

  /// Called once in MainShell.initState().
  /// Returns true if the employee hasn't registered their face yet.
  Future<bool> init() async {
    isAttendanceReady = false;
    notifyListeners();

    await syncTodayStatusFromServer();

    return await _fetchFaceRegistrationStatus();
  }

  void refreshTodayStatus() => _loadTodayStatus();

  Future<bool> syncTodayStatusFromServer() async {
    final success = await SessionManager.loadFromApi(name);
    attendanceSyncFailed = !success;
    isAttendanceReady = true;
    _loadTodayStatus();
    return success;
  }

  void _loadTodayStatus() {
    final masukRecord = SessionManager.getTodayRecord(name, 'Masuk');
    final pulangRecord = SessionManager.getTodayRecord(name, 'Pulang');

    isClockedIn = masukRecord != null;
    clockInTime = masukRecord == null
        ? '--:--'
        : DateFormat('HH:mm').format(masukRecord.timestamp);
    timestampMasuk = masukRecord?.timestamp;
    latitudeMasuk = masukRecord?.latitude;
    longitudeMasuk = masukRecord?.longitude;
    alamatMasuk = masukRecord?.locationName;

    clockOutTime = pulangRecord == null
        ? '--:--'
        : DateFormat('HH:mm').format(pulangRecord.timestamp);
    timestampPulang = pulangRecord?.timestamp;
    latitudePulang = pulangRecord?.latitude;
    longitudePulang = pulangRecord?.longitude;
    alamatPulang = pulangRecord?.locationName;

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

      // If registered, fetch & cache embeddings for on-device matching
      if (isFaceRegistered) {
        await _cacheEmbeddingsFromServer();
      }
    } catch (_) {
      // If the server cannot be reached, check if we have cached embeddings
      final cached = await FaceRecognitionService.getCachedEmbeddings();
      isFaceRegistered = cached != null && cached.isNotEmpty;
    } finally {
      isCheckingFace = false;
      notifyListeners();
    }
    return !isFaceRegistered;
  }

  /// Fetch embeddings from server and cache locally (non-blocking).
  Future<void> _cacheEmbeddingsFromServer() async {
    try {
      final embeddings = await FaceApiService.fetchStoredEmbeddings();
      if (embeddings != null && embeddings.isNotEmpty) {
        await FaceRecognitionService.cacheEmbeddings(embeddings);
      }
    } catch (_) {
      // Ignore — cached embeddings remain from last successful fetch
    }
  }

  // ── Clock In & Out ──

  Future<AttendanceResult> clockIn(File photo, List<double> embedding) =>
      _processAttendance(photo, embedding, 'Masuk');

  Future<AttendanceResult> clockOut(File photo, List<double> embedding) =>
      _processAttendance(photo, embedding, 'Pulang');

  /// Unified attendance flow — face verification is now ON-DEVICE.
  Future<AttendanceResult> _processAttendance(
    File photoFile,
    List<double> currentEmbedding,
    String type,
  ) async {
    try {
      await syncTodayStatusFromServer();
      final hasClockInToday =
          SessionManager.getTodayRecord(name, 'Masuk') != null;
      final hasClockOutToday =
          SessionManager.getTodayRecord(name, 'Pulang') != null;
      if (type == 'Masuk' && hasClockInToday) {
        return const AttendanceResult(
          success: false,
          message: 'Kamu sudah absen masuk hari ini.',
        );
      }

      if (type == 'Pulang') {
        if (!hasClockInToday) {
          return const AttendanceResult(
            success: false,
            message: 'Absen masuk terlebih dahulu sebelum absen pulang.',
          );
        }
        if (hasClockOutToday) {
          return const AttendanceResult(
            success: false,
            message: 'Kamu sudah absen pulang hari ini.',
          );
        }
      }

      // 1. Verify face ON-DEVICE
      _setLoading(true, '🔍 Memverifikasi wajah...');

      if (kDebugMode && AppConstants.devAttendanceBypass) {
        // Skip face verification in dev mode
      } else {
        var storedEmbeddings =
            await FaceRecognitionService.getCachedEmbeddings();
        if (storedEmbeddings == null || storedEmbeddings.isEmpty) {
          await _cacheEmbeddingsFromServer();
          storedEmbeddings = await FaceRecognitionService.getCachedEmbeddings();
        }
        if (storedEmbeddings == null || storedEmbeddings.isEmpty) {
          _setLoading(false);
          return const AttendanceResult(
            success: false,
            message:
                'Data wajah tidak ditemukan.\nPastikan koneksi internet tersedia dan coba lagi.',
          );
        }

        final matchResult = FaceRecognitionService.compareFaces(
          currentEmbedding,
          storedEmbeddings,
        );

        if (!matchResult.match) {
          _setLoading(false);
          return AttendanceResult(
            success: false,
            message:
                '${matchResult.message}\n(Confidence: ${matchResult.confidence.toStringAsFixed(1)}%)',
          );
        }
      }

      // 2. Get location
      _setLoading(true, '📍 Mengambil lokasi...');
      final position = await LocationService.getCurrentLocation();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final locationName = _formatAddress(placemarks.first);

      // 3. Save attendance
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

      final attendanceData = {
        'type': type,
        'timestamp': now.toIso8601String(),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'location_name': locationName,
      };

      // Send directly to server. Attendance is not accepted when the request fails.
      try {
        await ApiService.sendAttendance(attendanceData);
      } on ApiException catch (e) {
        await syncTodayStatusFromServer();
        _setLoading(false);
        return AttendanceResult(success: false, message: e.message);
      } catch (_) {
        _setLoading(false);
        return const AttendanceResult(
          success: false,
          message:
              'Gagal menyimpan data absensi.\nPastikan koneksi internet tersedia lalu coba lagi.',
        );
      }

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
        message: '✅ Absen $type berhasil!\nJam: $formattedTime',
        time: formattedTime,
      );
    } on TimeoutException {
      _setLoading(false);
      return const AttendanceResult(
        success: false,
        message: '⏱️ Lokasi tidak tersedia.\nPastikan GPS aktif dan coba lagi.',
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

  String _formatAddress(Placemark place) {
    final parts = <String?>[
      place.street,
      place.subLocality,
      place.locality,
      place.subAdministrativeArea,
      place.administrativeArea,
      place.postalCode,
      place.country,
    ];

    final cleanParts = <String>[];
    for (final raw in parts) {
      final value = _cleanAddressPart(raw);
      if (value == null) continue;
      final alreadyAdded = cleanParts.any(
        (part) => part.toLowerCase() == value.toLowerCase(),
      );
      if (!alreadyAdded) cleanParts.add(value);
    }

    return cleanParts.isEmpty ? 'Alamat tidak tersedia' : cleanParts.join(', ');
  }

  String? _cleanAddressPart(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    final withoutPlusCode = trimmed
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty && !_isPlusCode(part))
        .join(', ');

    return withoutPlusCode.isEmpty ? null : withoutPlusCode;
  }

  bool _isPlusCode(String value) {
    return RegExp(
      r'^[23456789CFGHJMPQRVWX]{4,8}\+[23456789CFGHJMPQRVWX]{2,3}$',
    ).hasMatch(value.toUpperCase());
  }

  // Register Face

  Future<AttendanceResult> registerFace(
    List<File> photos,
    List<List<double>> embeddings,
  ) async {
    try {
      if (kDebugMode && AppConstants.devAttendanceBypass) {
        isFaceRegistered = true;
        notifyListeners();
        return const AttendanceResult(
          success: true,
          message: 'Mode emulator: registrasi wajah dilewati.',
        );
      }

      if (!FaceRecognitionService.areEmbeddingsConsistent(embeddings)) {
        return const AttendanceResult(
          success: false,
          message:
              'Foto registrasi wajah tidak konsisten. Pastikan ketiga foto memakai wajah orang yang sama dan terlihat jelas.',
        );
      }

      _setLoading(
        true,
        '📡 Mengirim data wajah ke server...\nIni mungkin memerlukan beberapa detik',
      );

      // Send embeddings (NOT photos) to server
      final regResult = await FaceApiService.registerEmbeddings(embeddings);

      if (regResult.success) {
        // Cache embeddings locally for on-device matching
        await FaceRecognitionService.cacheEmbeddings(embeddings);
        isFaceRegistered = true;
        notifyListeners();
      }

      _setLoading(false);

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
