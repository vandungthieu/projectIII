import 'package:get/get.dart';
import 'package:mobile_project/controller/auth_controller.dart';
import 'package:mobile_project/models/sensorData.dart';
import 'package:mobile_project/service/sensorData_service.dart';

class SensorDataController extends GetxController {
  final SensorDataService _service = SensorDataService();

  /// 🔥 Device đang được xem
  final RxnInt currentDeviceId = RxnInt();

  var error = RxnString();
  final isLoading = false.obs;

  final sensorList = <SensorData>[].obs;

  String get token => Get.find<AuthController>().token ?? '';

  // ================== PUBLIC API ==================

  /// Gọi khi vào DeviceDetailScreen
  Future<void> setDevice(int deviceId) async {
    // Nếu cùng device → không load lại
    if (currentDeviceId.value == deviceId) return;

    currentDeviceId.value = deviceId;
    sensorList.clear();

    await _loadSensorData();
  }

  /// Refresh thủ công (pull to refresh)
  Future<void> refreshData() async {
    if (currentDeviceId.value == null) return;
    await _loadSensorData();
  }

  /// Nhận data realtime từ socket
  void updateFromSocket(dynamic json) {
    try {
      final data = SensorData.fromJson(json);

      // ❗ Chỉ nhận data của device đang mở
      if (data.deviceId != currentDeviceId.value) return;

      sensorList.insert(0, data);
      sensorList.refresh();
    } catch (e) {
      print("❌ Parse sensorData socket error: $e");
    }
  }

  // ================== INTERNAL ==================

  Future<void> _loadSensorData() async {
    if (currentDeviceId.value == null) return;

    try {
      isLoading(true);
      error.value = null;

      final result = await _service.getSensorDataByDevice(
        token,
        currentDeviceId.value!,
      );

      if (result != null) {
        sensorList.assignAll(result);
      } else {
        error.value = "Không tải được dữ liệu cảm biến";
      }
    } finally {
      isLoading(false);
    }
  }
}
