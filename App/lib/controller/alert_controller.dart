import 'package:get/get.dart';
import 'package:mobile_project/controller/auth_controller.dart';
import 'package:mobile_project/models/alert.dart';
import 'package:mobile_project/service/alert_service.dart';
import 'package:mobile_project/service/notification_service.dart';

class AlertController extends GetxController {
  final AlertService _service = AlertService();
  final NotificationService _notificationService =
      Get.find<NotificationService>();

  var alert = <Alert>[].obs;
  var filtered = <Alert>[].obs;

  var isLoading = true.obs;
  var error = RxnString();
  var togglingAlertId = RxnInt();

  final RxString searchText = ''.obs;

  String get token => Get.find<AuthController>().token;

  @override
  void onInit() {
    super.onInit();
    fetchAlert();
  }

  Future<void> fetchAlert() async {
    try {
      isLoading(true);
      error.value = null;

      final result = await _service.getMyAlert(token);
      if (result != null) {
        alert.assignAll(result);
        filtered.assignAll(result);
      } else {
        error.value = "Không tải được danh sách thiết bị";
      }
    } finally {
      isLoading(false);
    }
  }

  Future<void> refreshAlert() => fetchAlert();

  // search alert
  void search(String keyword) {
    searchText.value = keyword;
    final lower = keyword.toLowerCase().trim();

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

      // 1. Thêm alert mới lên đầu list
      alert.insert(0, alertModel);
      filtered.insert(0, alertModel);

      alert.refresh();
      filtered.refresh();

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
}
