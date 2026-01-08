class SensorData {
  final int id;
  final int deviceId;
  final Map<String, dynamic>? location;
  final double? speed;
  final DateTime createdAt;

  SensorData({
    required this.id,
    required this.deviceId,
    this.location,
    this.speed,
    required this.createdAt,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      id: json['id'],
      deviceId: json['deviceId'],
      location: json['location'],
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
