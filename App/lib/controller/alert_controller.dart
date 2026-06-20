import 'package:get/get.dart';
import 'package:mobile_project/controller/auth_controller.dart';
import 'package:mobile_project/models/alert.dart';
import 'package:mobile_project/service/alert_service.dart';
import 'package:mobile_project/service/notification_service.dart';

class AlertController extends GetxController {
  final AlertService _service = AlertService();
  int _requestVersion = 0;
  final NotificationService _notificationService =
      Get.find<NotificationService>();

  var alert = <Alert>[].obs;
  var allAlerts = <Alert>[].obs;
  var filtered = <Alert>[].obs;

  var isLoading = true.obs;
  var error = RxnString();
  var togglingAlertId = RxnInt();

  final RxString searchText = ''.obs;
  final selectedDate = Rxn<DateTime>();
  final selectedDeviceId = RxnInt();

  String get token => Get.find<AuthController>().token;

  @override
  void onInit() {
    super.onInit();
    fetchAlert();
  }

  Future<void> fetchAlert() async {
    final requestVersion = ++_requestVersion;
    final from = _selectedDayStart;
    final to = _selectedDayEnd;
    final deviceId = selectedDeviceId.value;

    try {
      isLoading(true);
      error.value = null;

      final result = await _service.getMyAlert(
        token,
        from: from,
        to: to,
        deviceId: deviceId,
      );
      if (requestVersion != _requestVersion) return;

      if (result != null) {
        alert.assignAll(result);
        if (selectedDate.value == null && selectedDeviceId.value == null) {
          allAlerts.assignAll(result);
        }
        _applySearch();
      } else {
        error.value = "Không tải được danh sách cảnh báo";
      }
    } finally {
      if (requestVersion == _requestVersion) isLoading(false);
    }
  }

  Future<void> refreshAlert() => fetchAlert();

  Future<void> refreshAllAlerts() async {
    final result = await _service.getMyAlert(token);
    if (result == null) return;

    allAlerts.assignAll(result);
    if (selectedDate.value == null) {
      alert.assignAll(result);
      _applySearch();
    }
  }

  Future<void> setDate(DateTime? date) async {
    selectedDate.value = date == null
        ? null
        : DateTime(date.year, date.month, date.day);
    await fetchAlert();
  }

  Future<void> setDevice(int? deviceId) async {
    selectedDeviceId.value = deviceId;
    await fetchAlert();
  }

  Future<void> clearFilters() async {
    selectedDate.value = null;
    selectedDeviceId.value = null;
    await fetchAlert();
  }

  // search alert
  void search(String keyword) {
    searchText.value = keyword;
    _applySearch();
  }

  void _applySearch() {
    final lower = searchText.value.toLowerCase().trim();

    // Danh sách gốc
    final List<Alert> source =
        alert; // giả sử bạn có GetX list: RxList<Alert> alert

    if (lower.isEmpty) {
      filtered.assignAll(source);
      return;
    }

    // Lọc trước
    final List<Alert> result = source.where((d) {
      final deviceCode = d.deviceCode.toString();
      final message = d.message.toLowerCase();

      final matchesDeviceId = deviceCode.contains(lower);
      final matchesMessage = message.contains(lower);

      return matchesDeviceId || matchesMessage;
    }).toList();

    // Sắp xếp thông minh
    result.sort((a, b) {
      final aId = a.deviceCode.toString().toLowerCase();
      final bId = b.deviceCode.toString().toLowerCase();
      final aMsg = a.message.toLowerCase();
      final bMsg = b.message.toLowerCase();

      // 1. Exact match (deviceId hoặc message)
      final aExact =
          aId == lower ||
          aMsg.contains(lower) &&
              aMsg.replaceAll(RegExp(r'[^a-z0-9]'), '') ==
                  lower.replaceAll(RegExp(r'[^a-z0-9]'), '');
      final bExact =
          bId == lower ||
          bMsg.contains(lower) &&
              bMsg.replaceAll(RegExp(r'[^a-z0-9]'), '') ==
                  lower.replaceAll(RegExp(r'[^a-z0-9]'), '');

      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;

      // 2. Starts with (deviceId hoặc message)
      final aStartsWith = aId.startsWith(lower) || aMsg.startsWith(lower);
      final bStartsWith = bId.startsWith(lower) || bMsg.startsWith(lower);

      if (aStartsWith && !bStartsWith) return -1;
      if (!aStartsWith && bStartsWith) return 1;

      // 3. Nếu cùng startsWith → ưu tiên chuỗi ngắn hơn
      if (aStartsWith && bStartsWith) {
        final aLen = _minLengthStartingWith(aId, aMsg, lower);
        final bLen = _minLengthStartingWith(bId, bMsg, lower);

        if (aLen != bLen) {
          return aLen.compareTo(bLen); // ngắn hơn lên trước
        }
      }

      // 4. Cuối cùng sắp xếp theo deviceId (hoặc id)
      if (a.deviceCode != b.deviceCode) {
        return a.deviceCode.compareTo(b.deviceCode);
      }
      return a.id.compareTo(b.id);
    });

    filtered.assignAll(result);
  }

  // Helper: tìm độ dài ngắn nhất của trường nào đó bắt đầu bằng keyword
  int _minLengthStartingWith(String idStr, String msg, String keyword) {
    final lengths = <int>[];

    if (idStr.toLowerCase().startsWith(keyword)) {
      lengths.add(idStr.length);
    }
    if (msg.toLowerCase().startsWith(keyword)) {
      lengths.add(msg.length);
    }

    return lengths.isEmpty ? 999999 : lengths.reduce((a, b) => a < b ? a : b);
  }

  /// Nhận alert realtime từ socket
  Future<void> addAlertFromSocket(dynamic alertJson) async {
    try {
      final alertModel = Alert.fromJson(alertJson);

      allAlerts.insert(0, alertModel);
      allAlerts.refresh();

      if (_matchesSelectedDate(alertModel.createdAt) &&
          _matchesSelectedDevice(alertModel.deviceId)) {
        alert.insert(0, alertModel);
        alert.refresh();
        _applySearch();
      }

      final isCritical =
          alertModel.severity?.toLowerCase() == 'high' ||
          alertModel.vehicleStatus?.toLowerCase() == 'stolen';
      final deviceName = alertModel.licensePlate?.trim().isNotEmpty == true
          ? alertModel.licensePlate!
          : alertModel.deviceCode;

      await _notificationService.showSecurityAlert(
        id: alertModel.id,
        title: isCritical ? 'Canh bao khan cap' : 'Canh bao moi',
        body: '$deviceName: ${alertModel.message}',
        critical: isCritical,
        payload: 'alert:${alertModel.id}',
      );
    } catch (e) {
      print(" Parse alert socket error: $e");
    }
  }

  DateTime? get _selectedDayStart {
    final date = selectedDate.value;
    if (date == null) return null;
    return DateTime(date.year, date.month, date.day);
  }

  DateTime? get _selectedDayEnd {
    final start = _selectedDayStart;
    return start?.add(const Duration(days: 1));
  }

  bool _matchesSelectedDate(DateTime value) {
    final selected = selectedDate.value;
    if (selected == null) return true;
    final local = value.toLocal();
    return local.year == selected.year &&
        local.month == selected.month &&
        local.day == selected.day;
  }

  bool _matchesSelectedDevice(int deviceId) {
    final selected = selectedDeviceId.value;
    return selected == null || selected == deviceId;
  }
}
