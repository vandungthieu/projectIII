import 'package:flutter/material.dart';
import 'package:mobile_project/models/device.dart';
import 'package:mobile_project/utils/app_themes.dart';

class DeviceFilterBar extends StatelessWidget {
  final List<Device> devices;
  final int? selectedDeviceId;
  final ValueChanged<int?> onChanged;

  const DeviceFilterBar({
    super.key,
    required this.devices,
    required this.selectedDeviceId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final availableIds = devices.map((device) => device.id).toSet();
    final value =
        selectedDeviceId != null && availableIds.contains(selectedDeviceId)
        ? selectedDeviceId!
        : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_car_outlined, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: value,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(
                    value: 0,
                    child: Text('Tất cả thiết bị'),
                  ),
                  ...devices.map(
                    (device) => DropdownMenuItem(
                      value: device.id,
                      child: Text(
                        device.licensePlate?.trim().isNotEmpty == true
                            ? '${device.licensePlate} (${device.deviceId})'
                            : device.deviceId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (deviceId) =>
                    onChanged(deviceId == 0 ? null : deviceId),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
