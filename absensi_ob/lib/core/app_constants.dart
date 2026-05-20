class AppConstants {
  AppConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://mobile-attendance-face-recognition-production.up.railway.app/api',
  );
  // static const String baseUrl = String.fromEnvironment(
  //   'API_BASE_URL',
  //   defaultValue: 'http://192.168.100.17:8000/api',
  // );

  // static const String baseUrl = String.fromEnvironment(
  //   'API_BASE_URL',
  //   defaultValue: 'http://10.236.245.236:8000/api',
  // );

  static const Duration requestTimeout = Duration(seconds: 30);
  static const bool devAttendanceBypass = bool.fromEnvironment(
    'DEV_ATTENDANCE_BYPASS',
    defaultValue: false,
  );

  static const List<String> faceRegisterInstructions = [
    'Foto 1/3 - Hadap depan, tatap kamera',
    'Foto 2/3 - Sedikit miring ke kiri',
    'Foto 3/3 - Sedikit miring ke kanan',
  ];
}
