import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';
import 'token_storage.dart';

/// Face API Service — Simplified for on-device face recognition.
///
/// With on-device MobileFaceNet, this service now only handles:
/// 1. Sending embeddings to the server (registration)
/// 2. Fetching stored embeddings from the server (for local caching)
/// 3. Checking face registration status
///
/// Face verification is no longer done via API — it happens on-device.
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

  /// Register face embeddings (extracted on-device) to the server.
  ///
  /// [embeddings] – List of 192-dim vectors extracted from 3+ photos.
  static Future<FaceResponse> registerEmbeddings(
    List<List<double>> embeddings,
  ) async {
    if (embeddings.isEmpty) {
      throw Exception('Minimal 1 embedding diperlukan');
    }

    final response = await http
        .post(
          Uri.parse('${AppConstants.baseUrl}/face/register'),
          headers: await _authHeaders(),
          body: jsonEncode({'embeddings': embeddings}),
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

  /// Fetch stored embeddings from the server (for local cache / local use).
  static Future<List<List<double>>?> fetchStoredEmbeddings() async {
    final response = await _sendWithRetry(
      () async => http
          .get(
            Uri.parse('${AppConstants.baseUrl}/face/embeddings'),
            headers: await _authHeaders(),
          )
          .timeout(AppConstants.requestTimeout),
    );

    if (response.statusCode != 200) return null;

    try {
      final data = jsonDecode(response.body);
      final raw = data['embeddings'];
      if (raw == null) return null;

      final embeddings = (raw as List)
          .map(
            (e) => List<double>.from(
              (e as List).map((v) => (v as num).toDouble()),
            ),
          )
          .toList();
      return embeddings.isNotEmpty ? embeddings : null;
    } catch (_) {
      return null;
    }
  }

  /// Check if the user has registered their face.
  static Future<bool> checkFaceRegistration() async {
    final response = await http
        .get(
          Uri.parse('${AppConstants.baseUrl}/face/check'),
          headers: await _authHeaders(),
        )
        .timeout(AppConstants.requestTimeout);

    if (response.statusCode != 200) return false;

    final data = jsonDecode(response.body);
    return data['registered'] ?? false;
  }

  static Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request();
    } on TimeoutException {
      return request();
    } on SocketException {
      return request();
    }
  }
}

/// Response model from the server.
class FaceResponse {
  final bool success;
  final String message;

  FaceResponse({required this.success, required this.message});

  factory FaceResponse.fromJson(Map<String, dynamic> json) {
    return FaceResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}
