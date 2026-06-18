// lib/models/device.dart
import 'package:mobile_project/models/sensorData.dart';

enum VehicleStatus { parked, moving, stolen, unknown }

class Device {
  final int id;
  final String deviceId; // cái này là UUID ngẫu nhiên
  final String? licensePlate;
  DateTime lastSeen;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? activatedAt;
  final String deviceKey;
  final bool isActivated;
  VehicleStatus vehicleStatus;
  bool buzzerStatus;
  final List<SensorData> sensorData; // lấy luôn vị trí mới nhất

  // Tính toán tiện dùng trong UI
  double get lat => latestLocation?['lat'] is num
      ? (latestLocation!['lat'] as num).toDouble()
      : 0.0;
  double get lng => latestLocation?['lng'] is num
      ? (latestLocation!['lng'] as num).toDouble()
      : 0.0;

  Map<String, dynamic>? get latestLocation {
    if (sensorData.isEmpty) return null;
    // Sắp xếp giảm dần theo createdAt, lấy cái mới nhất
    final latest = sensorData.reduce(
      (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
    );
    return latest.location;
  }

  Device({
    required this.id,
    required this.deviceId,
    this.licensePlate,
    required this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
    this.activatedAt,
    required this.deviceKey,
    required this.isActivated,
    required this.buzzerStatus,
    required this.vehicleStatus,
    this.sensorData = const [],
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    var sensorList = json['sensorData'] as List<dynamic>? ?? [];

    return Device(
      id: json['id'] as int,
      deviceId: json['deviceId'] as String,
      licensePlate: json['licensePlate'] as String?,
      lastSeen: DateTime.parse(json['lastSeen'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      activatedAt: json['activatedAt'] != null
          ? DateTime.parse(json['activatedAt'])
          : null,
      deviceKey: json['deviceKey'] as String,
      isActivated: json['isActivated'] as bool,
      vehicleStatus: _parseVehicleStatus(json['vehicleStatus'] as String?),
      buzzerStatus: json['buzzerStatus'] as bool? ?? false,
      sensorData: sensorList
          .map((e) => SensorData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static VehicleStatus _parseVehicleStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'moving':
        return VehicleStatus.moving;
      case 'parked':
        return VehicleStatus.parked;
      case 'stolen':
        return VehicleStatus.stolen;
      default:
        return VehicleStatus.unknown;
    }
  }
}
