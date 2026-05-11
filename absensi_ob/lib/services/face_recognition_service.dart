import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../core/app_constants.dart';
import 'token_storage.dart';

class FaceRecognitionService {
  FaceRecognitionService._();

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static FaceDetector? _faceDetector;

  static Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sesi login tidak ditemukan. Silakan login ulang.');
    }

    return {..._headers, 'Authorization': 'Bearer $token'};
  }

  static Future<FaceDetector> _getFaceDetector() async {
    try {
      return _faceDetector ??= FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableLandmarks: false,
        ),
      );
    } catch (e) {
      debugPrint('Face detector initialization error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> registerFaceMultiple({
    required List<File> imageFiles,
  }) async {
    final base64Images = <String>[];

    for (final imageFile in imageFiles) {
      if (!await _hasFace(imageFile)) {
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

  static Future<Map<String, dynamic>> verifyFace({
    required File imageFile,
  }) async {
    if (!await _hasFace(imageFile)) {
      return {
        'success': false,
        'match': false,
        'message': 'Wajah tidak terdeteksi',
      };
    }

    final response = await http
        .post(
          Uri.parse('${AppConstants.baseUrl}/face/verify'),
          headers: await _authHeaders(),
          body: jsonEncode({'image_base64': await _toBase64(imageFile)}),
        )
        .timeout(AppConstants.requestTimeout);

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<bool> _hasFace(File imageFile) async {
    try {
      final detector = await _getFaceDetector();
      final faces = await detector.processImage(InputImage.fromFile(imageFile));

      return faces.isNotEmpty;
    } catch (e) {
      debugPrint('Face detection error: $e');
      return false;
    }
  }

  static Future<String> _toBase64(File imageFile) async {
    final decoded = img.decodeImage(await imageFile.readAsBytes());
    if (decoded == null) throw Exception('Gagal decode gambar');

    final rgb = decoded.convert(numChannels: 3);

    return base64Encode(img.encodeJpg(rgb, quality: 85));
  }
}
