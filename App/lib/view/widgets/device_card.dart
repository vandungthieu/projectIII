import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_project/models/device.dart';
import 'package:mobile_project/utils/app_themes.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../controller/device_controller.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback? onTap;

  const DeviceCard({required this.device, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DeviceController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = _statusInfo(device.vehicleStatus);
    final title = (device.licensePlate?.trim().isNotEmpty ?? false)
        ? device.licensePlate!
        : device.deviceId;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(status.icon, color: status.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${device.deviceId}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(label: status.label, color: status.color),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.speed,
                      label: 'Tốc độ',
                      value: _latestSpeed(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.schedule,
                      label: 'Cập nhật',
                      value: timeago.format(device.lastSeen, locale: 'vi'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _InfoLine(
                icon: Icons.location_on_outlined,
                text: _locationText(),
              ),
              const SizedBox(height: 16),
              Obx(() {
                final isProtected =
                    device.vehicleStatus == VehicleStatus.parked;
                final isBuzzerOn = device.buzzerStatus;
                final isTogglingStatus =
                    ctrl.togglingDeviceId.value == device.id;
                final isTogglingBuzzer =
                    ctrl.togglingBuzzerId.value == device.id;

                return Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: isProtected
                            ? Icons.shield_outlined
                            : Icons.shield,
                        label: isProtected ? 'Tắt bảo vệ' : 'Bật bảo vệ',
                        color: isProtected
                            ? AppColors.success
                            : AppColors.warning,
                        isLoading: isTogglingStatus,
                        onPressed: device.isActivated
                            ? () =>
                                  ctrl.toggleVehicleStatus(device.id, isProtected)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        icon: isBuzzerOn
                            ? Icons.volume_up
                            : Icons.volume_off_outlined,
                        label: isBuzzerOn ? 'Còi đang bật' : 'Bật còi',
                        color: isBuzzerOn
                            ? AppColors.danger
                            : AppColors.primary,
                        isLoading: isTogglingBuzzer,
                        onPressed: device.isActivated
                            ? () => ctrl.toggleBuzzer(device.id, !isBuzzerOn)
                            : null,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  _StatusInfo _statusInfo(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.moving:
        return const _StatusInfo(
          label: 'Không bảo vệ',
          color: AppColors.warning,
          icon: Icons.shield_outlined,
        );
      case VehicleStatus.parked:
        return const _StatusInfo(
          label: 'Đang bảo vệ',
          color: AppColors.success,
          icon: Icons.shield,
        );
      case VehicleStatus.stolen:
        return const _StatusInfo(
          label: 'Nguy hiểm',
          color: AppColors.danger,
          icon: Icons.warning_amber_rounded,
        );
      case VehicleStatus.unknown:
        return const _StatusInfo(
          label: 'Không rõ',
          color: AppColors.muted,
          icon: Icons.help_outline,
        );
    }
  }

  String _latestSpeed() {
    if (device.sensorData.isEmpty || device.sensorData.first.speed == null) {
      return '-- km/h';
    }
    return '${device.sensorData.first.speed!.toStringAsFixed(1)} km/h';
  }

  String _locationText() {
    final location = device.latestLocation;
    if (location == null) return 'Chưa có vị trí gần nhất';
    final lat = (location['lat'] as num?)?.toDouble();
    final lng = (location['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return 'Chưa có vị trí gần nhất';
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusInfo({
    required this.label,
    required this.color,
    required this.icon,
  });
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.lightBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : AppColors.muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, size: 18, color: isDark ? Colors.white60 : AppColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.muted,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.35)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
