import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';

class PermissionService {
  PermissionService._();

  /// Request semua permissions yang dibutuhkan aplikasi
  static Future<bool> requestAllPermissions() async {
    try {
      // 1. Request Location Permission
      final locationPermission = await _requestLocationPermission();
      if (!locationPermission) {
        throw Exception('Location permission diperlukan untuk absensi');
      }

      // 2. Request Camera Permission
      final cameraPermission = await _requestCameraPermission();
      if (!cameraPermission) {
        throw Exception('Camera permission diperlukan untuk face recognition');
      }

      return true;
    } catch (e) {
      print('Permission error: $e');
      return false;
    }
  }

  static Future<bool> _requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        // User permanently denied permission
        return false;
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      print('Location permission error: $e');
      return false;
    }
  }

  static Future<bool> _requestCameraPermission() async {
    try {
      final cameras = await availableCameras();
      return cameras.isNotEmpty;
    } on CameraException catch (e) {
      print('Camera permission error: $e');
      return false;
    } catch (e) {
      print('Camera error: $e');
      return false;
    }
  }

  /// Check apakah semua permissions sudah granted
  static Future<bool> hasAllPermissions() async {
    try {
      // Check location
      final locationPermission = await Geolocator.checkPermission();
      final hasLocation =
          locationPermission == LocationPermission.whileInUse ||
          locationPermission == LocationPermission.always;

      // Check camera
      final cameras = await availableCameras();
      final hasCamera = cameras.isNotEmpty;

      return hasLocation && hasCamera;
    } catch (e) {
      return false;
    }
  }
}
