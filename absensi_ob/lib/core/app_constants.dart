/// Semua konstanta global project disimpan di sini.
class AppConstants {
  AppConstants._();

  // static const String baseUrl = String.fromEnvironment(
  //   'API_BASE_URL',
  //   defaultValue: 'http://192.168.100.17:8000/api',
  // );

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.236.245.236:8000/api',
  );

  static const String faceServerUrl = String.fromEnvironment(
    'FACE_SERVER_URL',
    defaultValue: 'http://192.168.100.17:5000',
  );

  /// Timeout default untuk semua HTTP request.
  static const Duration requestTimeout = Duration(seconds: 30);

  // Face recognition threshold
  static const double faceMatchThreshold = 0.4;

  // Instruksi foto saat registrasi wajah
  static const List<String> faceRegisterInstructions = [
    '📸 Foto 1/3 — Hadap depan, tatap kamera',
    '📸 Foto 2/3 — Sedikit miring ke kiri',
    '📸 Foto 3/3 — Sedikit miring ke kanan',
  ];
}
