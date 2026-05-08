import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import '../core/app_constants.dart';
import 'token_storage.dart';

class FaceRecognitionService {
  FaceRecognitionService._(); // prevent instantiation

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sesi login tidak ditemukan. Silakan login ulang.');
    }

    return {..._headers, 'Authorization': 'Bearer $token'};
  }

  // ✅ Dibuat sekali sebagai static instance — tidak dibuat ulang tiap request
  static FaceDetector? _faceDetector;

  static Future<FaceDetector> _getFaceDetector() async {
    if (_faceDetector == null) {
      try {
        _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            // fast cukup untuk pengecekan lokal (apakah ada wajah?)
            // accurate hanya perlu di server Python
            performanceMode: FaceDetectorMode.fast,
            enableLandmarks: false,
          ),
        );
      } catch (e) {
        print('Face detector initialization error: $e');
        rethrow;
      }
    }
    return _faceDetector!;
  }

  // ─── Registrasi dengan 3 foto ────────────────────────────────

  static Future<Map<String, dynamic>> registerFaceMultiple({
    required List<File> imageFiles,
    required String userId,
    required String userName,
  }) async {
    final List<String> base64Images = [];

    for (final imageFile in imageFiles) {
      final hasFace = await _hasFace(imageFile);
      if (!hasFace) {
        return {
          'success': false,
          'message': 'Wajah tidak terdeteksi di salah satu foto',
        };
      }
      base64Images.add(await _toBase64(imageFile));
    }

    final response = await http
        .post(
          Uri.parse('${AppConstants.baseUrl}/face/register-multiple'),
          headers: await _authHeaders(),
          body: jsonEncode({'images_base64': base64Images}),
        )
        .timeout(AppConstants.requestTimeout);

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─── Verifikasi wajah saat absen ─────────────────────────────

  static Future<Map<String, dynamic>> verifyFace({
    required File imageFile,
    required String userId,
  }) async {
    final hasFace = await _hasFace(imageFile);
    if (!hasFace) {
      return {
        'success': false,
        'match': false,
        'message': 'Wajah tidak terdeteksi',
      };
    }

    final base64Image = await _toBase64(imageFile);
    final response = await http
        .post(
          Uri.parse('${AppConstants.baseUrl}/face/verify'),
          headers: await _authHeaders(),
          body: jsonEncode({'image_base64': base64Image}),
        )
        .timeout(AppConstants.requestTimeout);

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─── Helper private ──────────────────────────────────────────

  /// Deteksi wajah secara lokal sebelum kirim ke server.
  /// Hemat bandwidth — cegah upload gambar yang tidak ada wajahnya.
  static Future<bool> _hasFace(File imageFile) async {
    try {
      final detector = await _getFaceDetector();
      final faces = await detector.processImage(InputImage.fromFile(imageFile));
      return faces.isNotEmpty;
    } catch (e) {
      print('Face detection error: $e');
      return false; // Fallback: assume no face if detection fails
    }
  }

  /// Konversi file gambar ke base64 JPEG yang bersih.
  static Future<String> _toBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Gagal decode gambar');

    // Buang alpha channel jika ada, encode ke JPEG
    final img.Image rgb = decoded.convert(numChannels: 3);
    final List<int> jpegBytes = img.encodeJpg(rgb, quality: 85);

    return base64Encode(jpegBytes);
  }
}
