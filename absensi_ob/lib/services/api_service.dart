import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';
import 'token_storage.dart';
import 'push_notification_service.dart';

/// ApiService bertanggung jawab penuh atas semua komunikasi HTTP ke Laravel.
/// Tidak ada logic bisnis di sini, hanya kirim dan terima data.
class ApiService {
  ApiService._(); // prevent instantiation

  static final _baseUrl = AppConstants.baseUrl;
  static final _timeout = AppConstants.requestTimeout;

  // Wajib ada Accept: application/json agar Laravel selalu return JSON,
  // bukan HTML error page (yang menyebabkan FormatException)
  static const Map<String, String> _baseHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<Map<String, String>> _headers({
    bool authenticated = false,
  }) async {
    if (!authenticated) return _baseHeaders;

    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sesi login tidak ditemukan. Silakan login ulang.');
    }

    return {..._baseHeaders, 'Authorization': 'Bearer $token'};
  }

  // --- Auth ---------------------------------------------------

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/login');
    if (kDebugMode) debugPrint('Login request: $uri');

    final response = await http
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({
            'username': username.trim().toLowerCase(),
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (kDebugMode) debugPrint('Login response: ${response.statusCode}');

    final data = _decodeJsonResponse(response);
    final token = data['token'];
    if (data['success'] == true && token is String) {
      await TokenStorage.saveToken(token);
      unawaited(PushNotificationService.syncTokenToServer());
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
    final data = _decodeJsonResponse(response);
    final token = data['token'];
    if (data['success'] == true && token is String) {
      await TokenStorage.saveToken(token);
      unawaited(PushNotificationService.syncTokenToServer());
    }
    return data;
  }

  static Future<Map<String, dynamic>> fetchCurrentEmployee() async {
    final response = await _sendWithRetry(
      () async => http
          .get(
            Uri.parse('$_baseUrl/user'),
            headers: await _headers(authenticated: true),
          )
          .timeout(_timeout),
    );
    return _decodeJsonResponse(response);
  }
  // --- Face ----------------------------------------------------

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
  }) async {
    final response = await http
        .put(
          Uri.parse('$_baseUrl/profile'),
          headers: await _headers(authenticated: true),
          body: jsonEncode({'name': name, 'phone': phone}),
        )
        .timeout(_timeout);
    return _decodeJsonResponse(response);
  }

  static Future<Map<String, dynamic>> uploadProfilePhoto(File photo) async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sesi login tidak ditemukan. Silakan login ulang.');
    }

    final request =
        http.MultipartRequest('POST', Uri.parse('$_baseUrl/profile/photo'))
          ..headers['Accept'] = 'application/json'
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(
            await http.MultipartFile.fromPath('profile_photo', photo.path),
          );

    final streamedResponse = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamedResponse);
    return _decodeJsonResponse(response);
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http
        .put(
          Uri.parse('$_baseUrl/profile/password'),
          headers: await _headers(authenticated: true),
          body: jsonEncode({
            'current_password': currentPassword,
            'password': password,
            'password_confirmation': passwordConfirmation,
          }),
        )
        .timeout(_timeout);
    return _decodeJsonResponse(response);
  }

  static Future<bool> checkFaceRegistration() async {
    final response = await _sendWithRetry(
      () async => http
          .get(
            Uri.parse('$_baseUrl/face/check'),
            headers: await _headers(authenticated: true),
          )
          .timeout(_timeout),
    );
    final data = _decodeJsonResponse(response);
    return data['registered'] == true;
  }

  // --- Attendance ----------------------------------------------

  static Future<void> sendAttendance(Map<String, dynamic> data) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/attendance'),
          headers: await _headers(authenticated: true),
          body: jsonEncode(data),
        )
        .timeout(_timeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      var message = 'Gagal menyimpan data absensi.';
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        message = data['message']?.toString() ?? message;
      } catch (_) {
        if (response.body.isNotEmpty) message = response.body;
      }
      throw ApiException(response.statusCode, message);
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAttendanceHistory() async {
    final response = await _sendWithRetry(
      () async => http
          .get(
            Uri.parse('$_baseUrl/attendance'),
            headers: await _headers(authenticated: true),
          )
          .timeout(_timeout),
    );

    final data = _decodeJsonResponse(response);
    if (data['success'] == true && data['data'] is List) {
      return List<Map<String, dynamic>>.from(data['data']);
    }
    return [];
  }

  // --- Requests -----------------------------------------------------------

  static Future<Map<String, dynamic>> submitLeaveRequest({
    required String leaveType,
    required String startDate,
    required String endDate,
    required bool isHalfDay,
    required String reason,
    String? contactDuringLeave,
    String? handoverNote,
    File? attachment,
  }) async {
    final request = await _multipartRequest('POST', '$_baseUrl/leave-requests');
    request.fields.addAll({
      'leave_type': leaveType,
      'start_date': startDate,
      'end_date': endDate,
      'is_half_day': isHalfDay ? '1' : '0',
      'reason': reason,
    });

    if (contactDuringLeave != null) {
      request.fields['contact_during_leave'] = contactDuringLeave;
    }
    if (handoverNote != null) {
      request.fields['handover_note'] = handoverNote;
    }
    if (attachment != null) {
      request.files.add(
        await http.MultipartFile.fromPath('attachment', attachment.path),
      );
    }

    final response = await _sendMultipart(request);
    return _decodeJsonResponse(response);
  }

  static Future<Map<String, dynamic>> submitCashAdvanceRequest({
    required int amount,
    required String purpose,
    required String neededDate,
    required String repaymentMethod,
    required String reason,
    String? disbursementMethod,
    String? accountNumber,
    File? attachment,
  }) async {
    final request = await _multipartRequest(
      'POST',
      '$_baseUrl/cash-advance-requests',
    );
    request.fields.addAll({
      'amount': amount.toString(),
      'purpose': purpose,
      'needed_date': neededDate,
      'repayment_method': repaymentMethod,
      'reason': reason,
    });

    if (disbursementMethod != null) {
      request.fields['disbursement_method'] = disbursementMethod;
    }
    if (accountNumber != null) {
      request.fields['account_number'] = accountNumber;
    }
    if (attachment != null) {
      request.files.add(
        await http.MultipartFile.fromPath('attachment', attachment.path),
      );
    }

    final response = await _sendMultipart(request);
    return _decodeJsonResponse(response);
  }

  static Future<List<Map<String, dynamic>>> fetchLeaveRequests() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/leave-requests'),
          headers: await _headers(authenticated: true),
        )
        .timeout(_timeout);

    return _decodePaginatedList(response);
  }

  static Future<Map<String, dynamic>> fetchLeaveBalance() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/leave-balance'),
          headers: await _headers(authenticated: true),
        )
        .timeout(_timeout);

    final data = _decodeJsonResponse(response);
    return Map<String, dynamic>.from(data['data'] as Map? ?? {});
  }

  static Future<List<Map<String, dynamic>>> fetchCashAdvanceRequests() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/cash-advance-requests'),
          headers: await _headers(authenticated: true),
        )
        .timeout(_timeout);

    return _decodePaginatedList(response);
  }

  static Future<Map<String, dynamic>> fetchCashAdvanceSummary() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/cash-advance-summary'),
          headers: await _headers(authenticated: true),
        )
        .timeout(_timeout);

    final data = _decodeJsonResponse(response);
    return Map<String, dynamic>.from(data['data'] as Map? ?? {});
  }

  static Future<http.MultipartRequest> _multipartRequest(
    String method,
    String url,
  ) async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sesi login tidak ditemukan. Silakan login ulang.');
    }

    return http.MultipartRequest(method, Uri.parse(url))
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token';
  }

  static Future<http.Response> _sendMultipart(
    http.MultipartRequest request,
  ) async {
    final streamed = await request.send().timeout(_timeout);
    return http.Response.fromStream(streamed);
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

  static Map<String, dynamic> _decodeJsonResponse(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final message = data['message'];
    if (message is String && message.isNotEmpty) {
      throw ApiException(response.statusCode, message);
    }

    throw ApiException(
      response.statusCode,
      'Request gagal (${response.statusCode}).',
    );
  }

  static List<Map<String, dynamic>> _decodePaginatedList(
    http.Response response,
  ) {
    final data = _decodeJsonResponse(response);
    final payload = data['data'];
    final items = payload is Map ? payload['data'] : payload;

    if (items is List) {
      return List<Map<String, dynamic>>.from(items);
    }

    return [];
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException ($statusCode): $message';
}
