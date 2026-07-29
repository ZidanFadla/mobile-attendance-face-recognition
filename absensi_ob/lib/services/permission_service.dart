import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class PermissionService {
  PermissionService._();

  /// Request semua permissions yang dibutuhkan aplikasi.
  static Future<bool> requestAllPermissions() async {
    try {
      final locationPermission = await _requestLocationPermission();
      if (!locationPermission) {
        throw Exception('Location permission diperlukan untuk absensi');
      }

      final cameraPermission = await _requestCameraPermission();
      if (!cameraPermission) {
        throw Exception('Camera permission diperlukan untuk face recognition');
      }

      return true;
    } catch (e) {
      debugPrint('Permission error: $e');
      return false;
    }
  }

  static Future<bool> _requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) return false;

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      debugPrint('Location permission error: $e');
      return false;
    }
  }

  static Future<bool> _requestCameraPermission() async {
    try {
      final cameras = await availableCameras();
      return cameras.isNotEmpty;
    } on CameraException catch (e) {
      debugPrint('Camera permission error: $e');
      return false;
    } catch (e) {
      debugPrint('Camera error: $e');
      return false;
    }
  }

}
