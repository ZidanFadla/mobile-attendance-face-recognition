class AppConstants {
  AppConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.100.17:8000/api',
  );

  static const Duration requestTimeout = Duration(seconds: 30);
  static const bool devAttendanceBypass = bool.fromEnvironment(
    'DEV_ATTENDANCE_BYPASS',
    defaultValue: false,
  );

  // Attendance business rules
  static const int clockInStartHour = 6;
  static const int clockInStartMinute = 0;
  static const int clockInEndHour = 8;
  static const int clockInEndMinute = 0;

  static const List<String> faceRegisterInstructions = [
    'Foto 1/3 - Hadap depan, tatap kamera',
    'Foto 2/3 - Sedikit miring ke kiri',
    'Foto 3/3 - Sedikit miring ke kanan',
  ];

  // Face Recognition (On-Device MobileFaceNet)
  static const String faceModelPath = 'assets/mobilefacenet.tflite';
  static const int faceInputSize = 112;
  static const int faceEmbeddingSize = 192;
  static const double faceMatchThreshold = 0.80; // L2 Euclidean distance
  static const double faceMatchThresholdRelaxed = 0.90;
  static const double faceRegistrationConsistencyThreshold = 1.05;
}
