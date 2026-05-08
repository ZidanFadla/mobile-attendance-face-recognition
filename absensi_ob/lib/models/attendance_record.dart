class AttendanceRecord {
  final String name;
  final String phoneNumber;
  final DateTime timestamp;
  final String type; // e.g., 'Masuk' (Clock-in), 'Pulang' (Clock-out)
  final double latitude;
  final double longitude;
  final String locationName;

  AttendanceRecord({
    required this.name,
    required this.phoneNumber,
    required this.timestamp,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });

  // Optional: A method to convert AttendanceRecord to a map, useful for persistence
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
    };
  }

  // Optional: A method to create AttendanceRecord from a map
  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      name: map['name'] as String,
      phoneNumber: map['phoneNumber'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      type: map['type'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      locationName: map['locationName'],
    );
  }
}
