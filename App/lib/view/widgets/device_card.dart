import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_project/models/device.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../controller/device_controller.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  const DeviceCard({required this.device, super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = Get.find<DeviceController>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // === Thông tin chính ===
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // biển số
                Text(
                  device.licensePlate ?? device.deviceId,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Trạng thái xe
                _buildInfoRow(
                  icon: Icons.directions_car,
                  label: "Trạng thái",
                  value: device.vehicleStatus.name.toUpperCase(),
                  color: device.vehicleStatus == VehicleStatus.moving
                      ? Colors.green
                      : Colors.orange,
                ),

                // Vị trí
                  _buildInfoRow(
                    icon: Icons.location_on,
                    label: "Vị trí",
                    value: "${device.lat.toStringAsFixed(6)}, ${device.lng.toStringAsFixed(6)}",
                  ),

                // Thời gian cập nhật
                _buildInfoRow(
                  icon: Icons.access_time,
                  label: "Cập nhật",
                  value: timeago.format(device.lastSeen, locale: 'vi'),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // === Trạng thái  ===
          // === Thêm vào trong Column bên phải (phần trạng thái) ===
// Thay thế toàn bộ phần Obx hiện tại bằng đoạn này:

          Obx(() {
            final ctrl = Get.find<DeviceController>();
            final isMoving = device.vehicleStatus == VehicleStatus.moving;
            final isBuzzerOn = device.buzzerStatus; // <-- Trạng thái còi

            final isTogglingStatus = ctrl.togglingDeviceId.value == device.id;
            final isTogglingBuzzer = ctrl.togglingBuzzerId.value == device.id; // <-- ID đang toggle buzzer

            return Column(
              children: [
                // === Toggle 1: Chống trộm (giữ nguyên như cũ) ===
                GestureDetector(
                  onTap: device.isActivated
                      ? () async {
                    await ctrl.toggleVehicleStatus(device.id, !isMoving);
                  }
                      : null,
                  child: _buildToggle(
                    isOn: isMoving,
                    isLoading: isTogglingStatus,
                    onText: "ĐANG CHẠY",
                    offText: "ĐANG ĐẬU",
                    onColor: Colors.green,
                    offColor: Colors.red,
                    onIcon: Icons.directions_car,
                    offIcon: Icons.local_parking,
                  ),
                ),

                const SizedBox(height: 12),

                // === Toggle 2: Còi báo động (MỚI) ===
                GestureDetector(
                  onTap: device.isActivated
                      ? () async {
                    await ctrl.toggleBuzzer(device.id, !isBuzzerOn);
                  }
                      : null,
                  child: _buildToggle(
                    isOn: isBuzzerOn,
                    isLoading: isTogglingBuzzer,
                    onText: "ĐANG KÊU",
                    offText: "IM LẶNG",
                    onColor: Colors.green,
                    offColor: Colors.grey,
                    onIcon: Icons.volume_up,
                    offIcon: Icons.volume_off,
                  ),
                ),

                const SizedBox(height: 8),

                // Text mô tả nhỏ cho buzzer
                Text(
                  isBuzzerOn ? "Còi: ĐANG KÊU" : "Còi: TẮT",
                  style: TextStyle(
                    fontSize: 10,
                    color: isBuzzerOn ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? Colors.grey[600]),
          const SizedBox(width: 6),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: TextStyle(color: color))),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required bool isOn,
    required bool isLoading,
    required String onText,
    required String offText,
    required Color onColor,
    required Color offColor,
    required IconData onIcon,
    required IconData offIcon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 70,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isOn
            ? onColor.withValues(alpha: 0.3)
            : offColor.withValues(alpha: 0.3),
        border: Border.all(
          color: isOn ? onColor : offColor,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Text trạng thái
          AnimatedAlign(
            alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
            duration: const Duration(milliseconds: 300),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                isOn ? onText : offText,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  color: isOn ? onColor : offColor,
                ),
              ),
            ),
          ),
          // Nút tròn + icon
          AnimatedAlign(
            alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: isLoading
                  ? const Padding(
                padding: EdgeInsets.all(4),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Icon(
                isOn ? onIcon : offIcon,
                size: 18,
                color: isOn ? onColor : offColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}