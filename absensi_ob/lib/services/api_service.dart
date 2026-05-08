import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';
import 'token_storage.dart';

/// ApiService bertanggung jawab penuh atas semua komunikasi HTTP ke Laravel.
/// Tidak ada logic bisnis di sini — hanya kirim & terima data.
class ApiService {
  ApiService._(); // prevent instantiation

  static final _baseUrl = AppConstants.baseUrl;
  static final _timeout = AppConstants.requestTimeout;

  // ✅ Wajib ada Accept: application/json agar Laravel selalu return JSON,
  // bukan HTML error page (yang menyebabkan FormatException)
  static const Map<String, String> _baseHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<Map<String, String>> _headers({bool authenticated = false}) async {
    if (!authenticated) return _baseHeaders;

    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sesi login tidak ditemukan. Silakan login ulang.');
    }

    return {
      ..._baseHeaders,
      'Authorization': 'Bearer $token',
    };
  }

  // ─── Auth ───────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/login'),
          headers: await _headers(),
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(_timeout);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'];
    if (data['success'] == true && token is String) {
      await TokenStorage.saveToken(token);
    }
    return data;
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String username,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/register'),
          headers: await _headers(),
          body: jsonEncode({
            'name': name,
            'phone': phone,
            'username': username,
            'password': password,
          }),
        )
        .timeout(_timeout);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'];
    if (data['success'] == true && token is String) {
      await TokenStorage.saveToken(token);
    }
    return data;
  }

  // ─── Face ────────────────────────────────────────────────────

  static Future<bool> checkFaceRegistration() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/face/check'),
          headers: await _headers(authenticated: true),
        )
        .timeout(_timeout);
    final data = jsonDecode(response.body);
    return data['registered'] == true;
  }

  // ─── Attendance ──────────────────────────────────────────────

  static Future<void> sendAttendance(Map<String, dynamic> data) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/attendance'),
          headers: await _headers(authenticated: true),
          body: jsonEncode(data),
        )
        .timeout(_timeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Gagal menyimpan data absensi: ${response.body}');
    }
  }
}
