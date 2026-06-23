class Alert {
  final int id;
  final int deviceId; // FK (logic)
  final String deviceCode; // HIỂN THỊ
  final int userId;
  final String message;
  final double? lat;
  final double? lng;
  final DateTime createdAt;
  final String? licensePlate;
  final String? severity;
  final String? vehicleStatus;

  Alert({
    required this.id,
    required this.deviceId,
    required this.deviceCode,
    required this.userId,
    required this.message,
    this.lat,
    this.lng,
    required this.createdAt,
    this.licensePlate,
    this.severity,
    this.vehicleStatus,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    double? latitude;
    double? longitude;

    // Parse location
    if (json['location'] != null && json['location'] is Map) {
      final loc = json['location'] as Map<String, dynamic>;
      latitude = _parseCoordinate(loc['lat'] ?? loc['latitude']);
      longitude = _parseCoordinate(
        loc['lng'] ?? loc['lon'] ?? loc['long'] ?? loc['longitude'],
      );
    }

    return Alert(
      id: json['id'] as int,
      deviceId: json['deviceId'] as int, // ✅ luôn int
      deviceCode: json['deviceCode'] as String, // ✅ dùng để hiển thị
      userId: json['userId'] as int,
      message: _localizeLegacyMessage(json['message'] as String),
      lat: latitude,
      lng: longitude,
      createdAt: DateTime.parse(json['createdAt'] as String),
      licensePlate: json['licensePlate'] as String?,
      severity: json['severity']?.toString(),
      vehicleStatus: json['vehicleStatus']?.toString(),
    );
  }

  // Lấy tốc độ từ message (20 hoặc 20.5 km/h)
  double? get speed {
    final match = RegExp(r'(\d+(?:\.\d+)?)\s*km/h').firstMatch(message);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  bool get hasLocation => lat != null && lng != null;

  static double? _parseCoordinate(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String _localizeLegacyMessage(String message) {
    if (!message.startsWith('Suspicious vehicle behavior:') &&
        !message.startsWith('Vehicle is moving abnormally')) {
      return message;
    }

    final speed = RegExp(
      r'speed ([\d.]+) km/h over threshold',
    ).firstMatch(message)?.group(1);
    final distance = RegExp(
      r'moved ([\d.]+) m away from parked location',
    ).firstMatch(message)?.group(1);
    final fallbackSpeed = RegExp(
      r'abnormally at ([\d.]+) km/h',
    ).firstMatch(message)?.group(1);

    final parts = <String>[
      if (speed != null) 'tốc độ $speed km/h vượt ngưỡng an toàn',
      if (distance != null) 'xe đã di chuyển $distance m khỏi vị trí bảo vệ',
    ];

    if (parts.isNotEmpty) {
      return 'Phát hiện xe di chuyển bất thường: ${parts.join(' và ')}.';
    }
    if (fallbackSpeed != null) {
      return 'Xe đang di chuyển bất thường với tốc độ $fallbackSpeed km/h!';
    }
    return message;
  }

  @override
  String toString() {
    return 'Alert{id: $id, deviceCode: $deviceCode, licensePlate: $licensePlate, speed: ${speed}km/h, location: ($lat, $lng), time: $createdAt}';
  }
}
