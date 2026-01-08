import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mobile_project/controller/sensorData_controller.dart';
import 'package:mobile_project/view/device_screen.dart';
import 'package:mobile_project/view/widgets/custom_textfield.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../controller/device_controller.dart';
import '../models/device.dart';
import '../models/sensorData.dart';
import '../utils/app_textstyles.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Device device;

  const DeviceDetailScreen({
    super.key,
    required this.device,
  });

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  late final SensorDataController sensorCtrl;
  //late final DeviceController deviceCtrl;

  @override
  void initState() {
    super.initState();

    sensorCtrl = Get.find<SensorDataController>();

    /// set device gọi API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sensorCtrl.setDevice(widget.device.id);
    });

  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // ---------- APP BAR ----------
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: Text(
          'Chi tiết thiết bị',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),

      // ---------- BODY ----------
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== DEVICE INFO =====
            _deviceInfo(widget.device, isDark),

            const SizedBox(height: 20),

            // ===== ACTION BUTTONS =====
            _actionButtons(widget.device),

            const SizedBox(height: 24),

            Text(
              "Dữ liệu cảm biến (Realtime)",
              style: AppTextStyle.h3,
            ),

            const SizedBox(height: 12),

            // ===== SENSOR LIST =====
            Expanded(
              child: Obx(() {
                if (sensorCtrl.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final list = sensorCtrl.sensorList;

                if (list.isEmpty) {
                  return const Center(
                    child: Text("Chưa có dữ liệu từ thiết bị"),
                  );
                }

                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, index) {
                    return _sensorDataRow(list[index]);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI COMPONENTS =================

  Widget _deviceInfo(Device device, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Device ID: ${device.deviceId}", style: AppTextStyle.h3),
          const SizedBox(height: 6),

          Text("Biển số: ${device.licensePlate ?? '--'}"),
          const SizedBox(height: 6),

          Text(
              "Thời gian kích hoạt: "
                  "${device.activatedAt != null
                  ? DateFormat('dd/MM/yyyy').format(device.activatedAt!)
                  : 'Chưa kích hoạt'}"

          ),
          const SizedBox(height: 6),

          Text(
            "Cập nhật gần nhất: ${DateFormat('dd/MM/yyyy').format(device.updatedAt)}",
          ),
          const SizedBox(height: 6),

          Text("KEY: ${device.deviceKey ?? '--'}"),
        ],
      ),
    );
  }

  Widget _actionButtons(Device device) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text("Chỉnh sửa biển số"),
            onPressed: () {
              _showUpdate(context);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text("Xóa thiết bị"),
            onPressed: () {
              _showRemoveDialog(context);
            },
          ),
        ),
      ],
    );
  }

  Widget _sensorDataRow(SensorData data) {
    final speed = data.speed ?? 0;
    final isOverSpeed = speed > 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.withValues(alpha: 0.06),
      ),
      child: Row(
        children: [
          // ===== SPEED =====
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.speed,
                  size: 18,
                  color: isOverSpeed ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 6),
                Text(
                  "$speed km/h",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isOverSpeed ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // ===== LOCATION =====
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.blueGrey,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    data.location == null
                        ? "--"
                        : "${data.location!['lat']}, ${data.location!['lng']}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(BuildContext context){
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceCtrl = Get.find<DeviceController>();

    Get.dialog(
        AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),

          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  shape:  BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete,
                  color: Theme.of(context).primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 8,),
              Text(
                'Are you sure want to remove device',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodyMedium,
                  isDark ? Colors.grey[400] ! : Colors.grey[600]!,
                ),
              ),
              const SizedBox(height: 24,),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48), // chiều cao nút
                        side: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTextStyle.withColor(
                          AppTextStyle.buttonMedium,
                          Theme.of(context).textTheme.bodyLarge!.color!,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12), // giảm từ 16 xuống 12

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        deviceCtrl.deleteMyDevice(widget.device.id);
                        Get.back(); // đóng dialog
                        Get.back(); // quay lại DeviceScreen

                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48), // chiều cao nút
                        backgroundColor: Theme.of(context).primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Remove',
                        style: AppTextStyle.withColor(
                          AppTextStyle.buttonMedium,
                          Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              )

            ],
          ),
        )
    );
  }

  void _showUpdate(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formKey = GlobalKey<FormState>();
    final deviceCtrl = Get.find<DeviceController>();
    final licensePlateController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),

        content: Form(
          key: formKey,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 360, // 🔥 giới hạn width → đẹp trên mọi màn
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  'Cập nhật biển số',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),

                const SizedBox(height: 20),

                // Input
                CustomTextfield(
                  label: 'License Plate',
                  prefixIcon: Icons.confirmation_number_outlined,
                  controller: licensePlateController,
                  //textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập biển số xe';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: Get.back,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          side: BorderSide(
                            color: isDark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Hủy'),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: ()  async {
                          if (formKey.currentState!.validate()){
                            bool success = await deviceCtrl.updateMyDevice(
                              deviceId: widget.device.id,
                              licensePlate:
                              licensePlateController.text.trim(),
                            );

                            if (success) {
                              Get.back(); // quay về
                              Get.back();
                              Get.snackbar(
                                "SUCCESS",
                                "Change License Plate",
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            } else {
                              Get.snackbar(
                                "FAILED",
                                "Change Failed",

                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }

                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          backgroundColor:
                          Theme.of(context).primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Lưu',
                          style: TextStyle(
                            color: Colors.white, // 🔥 QUAN TRỌNG
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
      ),
      barrierDismissible: false, // tránh bấm ngoài bị đóng
    );
  }

}
