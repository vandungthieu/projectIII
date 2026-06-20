class JourneyPoint {
  final int id;
  final double lat;
  final double lng;
  final double? speed;
  final DateTime createdAt;

  const JourneyPoint({
    required this.id,
    required this.lat,
    required this.lng,
    this.speed,
    required this.createdAt,
  });

  factory JourneyPoint.fromJson(Map<String, dynamic> json) {
    return JourneyPoint(
      id: json['id'] as int,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      speed: json['speed'] == null ? null : (json['speed'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class Journey {
  final List<JourneyPoint> points;
  final double distanceMeters;
  final int rawPointCount;
  final int ignoredPointCount;

  const Journey({
    required this.points,
    required this.distanceMeters,
    required this.rawPointCount,
    required this.ignoredPointCount,
  });

  factory Journey.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>? ?? const [];

    return Journey(
      points: rawPoints
          .map((item) => JourneyPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
      rawPointCount: json['rawPointCount'] as int? ?? rawPoints.length,
      ignoredPointCount: json['ignoredPointCount'] as int? ?? 0,
    );
  }
}
