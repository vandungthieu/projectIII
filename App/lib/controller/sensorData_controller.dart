import 'package:get/get.dart';
import 'package:mobile_project/controller/auth_controller.dart';
import 'package:mobile_project/models/journey.dart';
import 'package:mobile_project/models/sensorData.dart';
import 'package:mobile_project/service/sensorData_service.dart';

enum JourneyPeriod { day, week, all }

class SensorDataController extends GetxController {
  final SensorDataService _service = SensorDataService();
  int _sensorRequestVersion = 0;

  /// 🔥 Device đang được xem
  final RxnInt currentDeviceId = RxnInt();

  var error = RxnString();
  final isLoading = false.obs;
  final isJourneyLoading = false.obs;

  final sensorList = <SensorData>[].obs;
  final selectedSensorDate = Rxn<DateTime>();
  final journey = Rxn<Journey>();
  final journeyPeriod = JourneyPeriod.day.obs;

  String get token => Get.find<AuthController>().token;

  // ================== PUBLIC API ==================

  /// Gọi khi vào DeviceDetailScreen
  Future<void> setDevice(int deviceId) async {
    // Nếu cùng device → không load lại
    if (currentDeviceId.value == deviceId) return;

    currentDeviceId.value = deviceId;
    sensorList.clear();
    journey.value = null;

    await Future.wait([_loadSensorData(), _loadJourney()]);
  }

  /// Refresh thủ công (pull to refresh)
  Future<void> refreshData() async {
    if (currentDeviceId.value == null) return;
    await Future.wait([_loadSensorData(), _loadJourney()]);
  }

  Future<void> setJourneyPeriod(JourneyPeriod period) async {
    if (journeyPeriod.value == period) return;
    journeyPeriod.value = period;
    await _loadJourney();
  }

  Future<void> setSensorDate(DateTime? date) async {
    selectedSensorDate.value = date == null
        ? null
        : DateTime(date.year, date.month, date.day);
    await _loadSensorData();
  }

  /// Nhận data realtime từ socket
  void updateFromSocket(dynamic json) {
    try {
      final data = SensorData.fromJson(json);

      // ❗ Chỉ nhận data của device đang mở
      if (data.deviceId != currentDeviceId.value) return;
      if (!_matchesSelectedDate(data.createdAt)) return;

      sensorList.insert(0, data);
      sensorList.refresh();
    } catch (e) {
      print("❌ Parse sensorData socket error: $e");
    }
  }

  // ================== INTERNAL ==================

  Future<void> _loadSensorData() async {
    if (currentDeviceId.value == null) return;
    final requestVersion = ++_sensorRequestVersion;
    final deviceId = currentDeviceId.value!;
    final from = _selectedDayStart;
    final to = _selectedDayEnd;

    try {
      isLoading(true);
      error.value = null;

      final result = await _service.getSensorDataByDevice(
        token,
        deviceId,
        from: from,
        to: to,
      );

      if (requestVersion != _sensorRequestVersion) return;

      if (result != null) {
        sensorList.assignAll(result);
      } else {
        error.value = "Không tải được dữ liệu cảm biến";
      }
    } finally {
      if (requestVersion == _sensorRequestVersion) isLoading(false);
    }
  }

  DateTime? get _selectedDayStart {
    final date = selectedSensorDate.value;
    if (date == null) return null;
    return DateTime(date.year, date.month, date.day);
  }

  DateTime? get _selectedDayEnd {
    final start = _selectedDayStart;
    return start?.add(const Duration(days: 1));
  }

  bool _matchesSelectedDate(DateTime value) {
    final selected = selectedSensorDate.value;
    if (selected == null) return true;
    final local = value.toLocal();
    return local.year == selected.year &&
        local.month == selected.month &&
        local.day == selected.day;
  }

  Future<void> _loadJourney() async {
    if (currentDeviceId.value == null) return;

    try {
      isJourneyLoading(true);
      final deviceId = currentDeviceId.value!;
      final requestedPeriod = journeyPeriod.value;
      final now = DateTime.now();
      final from = switch (requestedPeriod) {
        JourneyPeriod.day => now.subtract(const Duration(hours: 24)),
        JourneyPeriod.week => now.subtract(const Duration(days: 7)),
        JourneyPeriod.all => null,
      };

      final result = await _service.getJourneyByDevice(
        token,
        deviceId,
        from: from,
        to: now,
      );
      if (currentDeviceId.value == deviceId &&
          journeyPeriod.value == requestedPeriod) {
        journey.value = result;
      }
    } finally {
      isJourneyLoading(false);
    }
  }
}
