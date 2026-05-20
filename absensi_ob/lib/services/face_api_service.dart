import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../core/app_constants.dart';
import 'token_storage.dart';

/// Clean & Simple Face API Service
/// Hanya handle API communication, no ML logic
class FaceApiService {
  FaceApiService._();

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

  /// Compress image untuk mengurangi ukuran transfer
  static Future<String> _compressImage(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Gagal decode gambar');

    // Resize jika terlalu besar (max 800px width)
    final resized = image.width > 800
        ? img.copyResize(image, width: 800)
        : image;

    // Convert to RGB dan compress
    final rgb = resized.convert(numChannels: 3);
    final compressed = img.encodeJpg(rgb, quality: 85);

    return base64Encode(compressed);
  }

  /// Register face dengan multiple images
  /// Server akan handle semua validasi (detection, quality, liveness)
  static Future<FaceResponse> registerFace(List<String> imagePaths) async {
    if (imagePaths.isEmpty) {
      throw Exception('Minimal 1 foto diperlukan');
    }

    // Compress semua images
    final compressedImages = <String>[];
    for (final path in imagePaths) {
      compressedImages.add(await _compressImage(path));
    }

    final response = await http
        .post(
          Uri.parse('${AppConstants.baseUrl}/face/register'),
          headers: await _authHeaders(),
          body: jsonEncode({'images': compressedImages}),
        )
        .timeout(AppConstants.requestTimeout);

    if (response.statusCode != 200) {
      String errMsg = 'Server error: ${response.statusCode}';
      try {
        final errData = jsonDecode(response.body);
        if (errData is Map && errData['message'] != null) {
          errMsg = errData['message'];
        }
      } catch (_) {}
      throw Exception(errMsg);
    }

    return FaceResponse.fromJson(jsonDecode(response.body));
  }

  /// Verify face untuk attendance
  /// Supports image atau video
  static Future<FaceResponse> verifyFace({
    required String filePath,
    bool isVideo = false,
  }) async {
    final body = isVideo
        ? {
            'video': base64Encode(await File(filePath).readAsBytes()),
            'type': 'video',
          }
        : {'image': await _compressImage(filePath), 'type': 'image'};

    final response = await http
        .post(
          Uri.parse('${AppConstants.baseUrl}/face/verify'),
          headers: await _authHeaders(),
          body: jsonEncode(body),
        )
        .timeout(AppConstants.requestTimeout);

    if (response.statusCode != 200) {
      String errMsg = 'Server error: ${response.statusCode}';
      try {
        final errData = jsonDecode(response.body);
        if (errData is Map && errData['message'] != null) {
          errMsg = errData['message'];
        }
      } catch (_) {}
      throw Exception(errMsg);
    }

    return FaceResponse.fromJson(jsonDecode(response.body));
  }

  /// Check apakah user sudah register face
  static Future<bool> checkFaceRegistration() async {
    final response = await http
        .get(
          Uri.parse('${AppConstants.baseUrl}/face/check'),
          headers: await _authHeaders(),
        )
        .timeout(AppConstants.requestTimeout);

    if (response.statusCode != 200) {
      return false;
    }

    final data = jsonDecode(response.body);
    return data['registered'] ?? false;
  }
}

/// Response model dari server
class FaceResponse {
  final bool success;
  final String message;
  final bool? match;
  final double? confidence;
  final Map<String, dynamic>? data;

  FaceResponse({
    required this.success,
    required this.message,
    this.match,
    this.confidence,
    this.data,
  });

  factory FaceResponse.fromJson(Map<String, dynamic> json) {
    return FaceResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      match: json['match'],
      confidence: json['confidence']?.toDouble(),
      data: json['data'],
    );
  }
}
