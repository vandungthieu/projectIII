import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_project/view/device_screen.dart';
import '../models/device.dart';
import '../models/sensorData.dart';
import '../service/device_service.dart';
import '../service/notification_service.dart';
import 'auth_controller.dart';

class DeviceController extends GetxController {
  final DeviceService _service = DeviceService();
  final NotificationService _notificationService =
      Get.find<NotificationService>();

  var devices = <Device>[].obs;
  var filtered = <Device>[].obs;

  final RxString searchText = ''.obs;
  final RxString statusFilter = 'all'.obs;

  var isLoading = true.obs;
  var error = RxnString();
  var togglingDeviceId = RxnInt();
  var togglingBuzzerId = RxnInt();

  /// Sensor data realtime theo deviceId
  final RxMap<int, List<SensorData>> sensorDataMap =
      <int, List<SensorData>>{}.obs;

  String get token => Get.find<AuthController>().token;

  @override
  void onInit() {
    super.onInit();
    fetchDevices();
  }

  Future<void> fetchDevices() async {
    try {
      isLoading(true);
      error.value = null;

      final result = await _service.getMyDevices(token);
      if (result != null) {
        devices.assignAll(result);
        _applyFilters();
      } else {
        error.value = "Không tải được danh sách thiết bị";
      }
    } finally {
      isLoading(false);
    }
  }

  // toggle vehicle
  Future<void> toggleVehicleStatus(int id, bool toMoving) async {
    final device = devices.firstWhere((d) => d.id == id);

    // Optimistic UI
    togglingDeviceId.value = id;
    final oldStatus = device.vehicleStatus;
    device.vehicleStatus = toMoving
        ? VehicleStatus.moving
        : VehicleStatus.parked;
    _refreshDeviceCollections();

    // Gọi API (bạn cần tạo endpoint này ở backend)
    final success = await _service.updateVehicleStatus(
      id: id,
      status: toMoving ? 'Moving' : 'Parked',
      token: token,
    );

    if (!success) {
      device.vehicleStatus = oldStatus;
      _refreshDeviceCollections();
      Get.snackbar(
        "Lỗi",
        "Không thể thay đổi trạng thái xe",
        backgroundColor: Colors.red,
      );
    }

    togglingDeviceId.value = null;
  }

  // toggle buzzer
  Future<void> toggleBuzzer(int deviceId, bool turnOn) async {
    final device = devices.firstWhere((d) => d.id == deviceId);

    togglingBuzzerId.value = deviceId;
    final oldBuzzerStatus = device.buzzerStatus;
    device.buzzerStatus = turnOn;
    _refreshDeviceCollections();

    // Gọi API
    final success = await _service.updateBuzzerStatus(
      deviceId: device.deviceId,
      turnOn: turnOn,
      token: token,
    );

    // Nếu thất bại → rollback
    if (!success) {
      device.buzzerStatus = oldBuzzerStatus;
      _refreshDeviceCollections();
      Get.snackbar(
        "Thất bại",
        "Không thể ${turnOn ? 'bật' : 'tắt'} còi báo động",
        backgroundColor: Colors.red,
      );
    } else {
      if (turnOn) {
        await _notificationService.showDeviceAction(
          id: device.id,
          title: 'Đã bật còi báo động',
          body: 'Thiết bị ${device.deviceId} đang phát còi báo động',
          payload: 'device:${device.id}:buzzer_on',
        );
      }
    }

    togglingBuzzerId.value = null;
  }

  Future<void> refreshDevices() => fetchDevices();

  // search device
  void search(String keyword) {
    searchText.value = keyword;
    _applyFilters();
  }

  void setStatusFilter(String value) {
    statusFilter.value = value;
    _applyFilters();
  }

  void _applyFilters() {
    final lower = searchText.value.toLowerCase().trim();
    final status = statusFilter.value;

    final result = devices.where((d) {
      final matchesStatus = switch (status) {
        'parked' => d.vehicleStatus == VehicleStatus.parked,
        'moving' => d.vehicleStatus == VehicleStatus.moving,
        'stolen' => d.vehicleStatus == VehicleStatus.stolen,
        'buzzer' => d.buzzerStatus,
        _ => true,
      };
      if (!matchesStatus) return false;
      if (lower.isEmpty) return true;

      final deviceId = d.deviceId.toLowerCase();
      final licensePlate = (d.licensePlate ?? "").toLowerCase();

      return deviceId == lower ||
          licensePlate == lower ||
          deviceId.startsWith(lower) ||
          licensePlate.startsWith(lower) ||
          deviceId.contains(lower) ||
          licensePlate.contains(lower);
    }).toList();

    // Sắp xếp FIXED - đầy đủ logic
    result.sort((a, b) {
      final aId = a.deviceId.toLowerCase();
      final bId = b.deviceId.toLowerCase();
      final aPlate = (a.licensePlate ?? "").toLowerCase();
      final bPlate = (b.licensePlate ?? "").toLowerCase();

      if (lower.isEmpty) {
        return aId.compareTo(bId);
      }

      // 1. Exact match cả ID và Plate
      if (aId == lower || aPlate == lower) {
        if (!(bId == lower || bPlate == lower)) return -1;
      }
      if (bId == lower || bPlate == lower) {
        if (!(aId == lower || aPlate == lower)) return 1;
      }

      // 2. Starts with cả ID và Plate
      final aStartsWith = aId.startsWith(lower) || aPlate.startsWith(lower);
      final bStartsWith = bId.startsWith(lower) || bPlate.startsWith(lower);

      if (aStartsWith && !bStartsWith) return -1;
      if (!aStartsWith && bStartsWith) return 1;

      // 3. Nếu cả hai đều startsWith, sắp xếp theo độ dài (ngắn hơn trước)
      if (aStartsWith && bStartsWith) {
        final aMinLength = [aId, aPlate]
            .where((s) => s.startsWith(lower))
            .map((s) => s.length)
            .reduce((a, b) => a < b ? a : b);

        final bMinLength = [bId, bPlate]
            .where((s) => s.startsWith(lower))
            .map((s) => s.length)
            .reduce((a, b) => a < b ? a : b);

        if (aMinLength != bMinLength) {
          return aMinLength.compareTo(bMinLength);
        }
      }

      // 4. Cuối cùng sắp xếp theo ID
      return aId.compareTo(bId);
    });

    filtered.assignAll(result);
  }

  void _refreshDeviceCollections() {
    devices.refresh();
    _applyFilters();
  }

  /// Đồng bộ trạng thái thiết bị từ cảnh báo Socket.IO hoặc dữ liệu FCM.
  void updateStatusFromRealtime(dynamic data) {
    if (data is! Map) return;

    final rawDeviceId = data['deviceId'];
    final deviceId = rawDeviceId is int
        ? rawDeviceId
        : int.tryParse(rawDeviceId?.toString() ?? '');
    final status = switch (data['vehicleStatus']?.toString().toLowerCase()) {
      'parked' => VehicleStatus.parked,
      'moving' => VehicleStatus.moving,
      'stolen' => VehicleStatus.stolen,
      _ => null,
    };

    if (deviceId == null || status == null) return;

    final index = devices.indexWhere((device) => device.id == deviceId);
    if (index < 0) return;

    final device = devices[index];
    device.vehicleStatus = status;

    final createdAt = DateTime.tryParse(data['createdAt']?.toString() ?? '');
    if (createdAt != null) device.lastSeen = createdAt;

    _refreshDeviceCollections();
  }

  // active device
  Future<void> activateDevice(String deviceId, String deviceKey) async {
    try {
      isLoading.value = true;

      await _service.activateDevice(
        deviceId: deviceId,
        deviceKey: deviceKey,
        token: token,
      );

      // Nếu đến đây tức là thành công
      Get.snackbar(
        "Thành công",
        "Thiết bị đã được kích hoạt",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Load lại danh sách thiết bị
      await fetchDevices();

      // quay lại device screen
      Get.off(() => DeviceScreen());
    } catch (e) {
      // API trả lỗi 400 hoặc 409
      Get.snackbar(
        "Kích hoạt thất bại",
        e.toString().replaceAll("Exception: ", ""),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Nhận SensorData realtime từ socket
  void sensorDataFromSocket(dynamic json) {
    try {
      final sensor = SensorData.fromJson(json);

      // lấy list hiện tại của device
      final list = sensorDataMap[sensor.deviceId] ?? <SensorData>[];

      // tránh trùng dữ liệu
      if (list.any((e) => e.id == sensor.id)) return;

      // thêm mới lên đầu
      list.insert(0, sensor);

      // giới hạn số lượng (vd 100 bản ghi gần nhất)
      if (list.length > 100) {
        list.removeRange(100, list.length);
      }

      sensorDataMap[sensor.deviceId] = list;
      sensorDataMap.refresh();
    } catch (e) {
      error.value = 'Lỗi khi xử lý SensorData realtime';
    }
  }

  // xóa thiết bị
  Future<void> deleteMyDevice(int deviceId) async {
    try {
      isLoading.value = true;

      await _service.deleteMyDevice(deviceId: deviceId, token: token);

      // Xoá device khỏi list local
      devices.removeWhere((e) => e.id == deviceId);
      await fetchDevices();

      Get.snackbar(
        'Success',
        'Device deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  /// Update device (license plate)
  Future<bool> updateMyDevice({
    required int deviceId,
    required String licensePlate,
  }) async {
    try {
      isLoading.value = true;

      final success = await _service.updateMyDevice(
        deviceId,
        licensePlate,
        token,
      );

      if (success) {
        // reload danh sách device
        await fetchDevices();
        return true;
      }

      return false;
    } catch (e) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
