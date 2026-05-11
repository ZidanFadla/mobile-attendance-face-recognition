import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._(); // prevent instantiation

  static Future<Position> getCurrentLocation() async {
    // 1. Cek apakah GPS aktif
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'GPS tidak aktif. Aktifkan lokasi di pengaturan perangkat.',
      );
    }

    // 2. Cek permission
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }
    }

    // ✅ Handle permanently denied — sebelumnya tidak dihandle, bisa infinite loop
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Izin lokasi ditolak secara permanen.\n'
        'Buka Pengaturan → Aplikasi → Absensi OB → Izin → Lokasi.',
      );
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ),
    );
  }
}
