import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_project/controller/alert_controller.dart';
import 'package:mobile_project/controller/auth_controller.dart';
import 'package:mobile_project/controller/device_controller.dart';
import 'package:mobile_project/controller/navigation_controller.dart';
import 'package:mobile_project/controller/theme_controller.dart';
import 'package:mobile_project/models/alert.dart';
import 'package:mobile_project/models/device.dart';
import 'package:mobile_project/utils/app_themes.dart';
import 'package:mobile_project/view/alert_detail_screen.dart';
import 'package:mobile_project/view/device_detail_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceCtrl = Get.find<DeviceController>();
    final alertCtrl = Get.find<AlertController>();
    final authCtrl = Get.find<AuthController>();
    final navCtrl = Get.find<NavigationController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Obx(() {
          final riskDevices = deviceCtrl.devices
              .where(
                (d) =>
                    d.vehicleStatus == VehicleStatus.moving ||
                    d.vehicleStatus == VehicleStatus.stolen ||
                    d.buzzerStatus,
              )
              .toList();
          final recentAlerts = alertCtrl.alert.take(3).toList();

          return RefreshIndicator(
            onRefresh: () => _refreshHome(deviceCtrl, alertCtrl),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: _Header(
                      name:
                          authCtrl.user.value?.name ??
                          authCtrl.user.value?.username ??
                          'Bạn',
                      isDark: isDark,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: _SafetyPanel(controller: deviceCtrl),
                  ),
                ),
                if (deviceCtrl.isLoading.value && deviceCtrl.devices.isEmpty)
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (deviceCtrl.error.value != null &&
                    deviceCtrl.devices.isEmpty)
                  SliverToBoxAdapter(
                    child: _StateMessage(
                      icon: Icons.wifi_off,
                      title: 'Không tải được dữ liệu',
                      message: deviceCtrl.error.value!,
                      actionLabel: 'Thử lại',
                      onAction: () => _refreshHome(deviceCtrl, alertCtrl),
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: _QuickActions(
                      onDevices: () => navCtrl.changeIndex(1),
                      onAlerts: () => navCtrl.changeIndex(2),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _RiskDevicesSection(
                      devices: riskDevices,
                      totalDevices: deviceCtrl.devices.length,
                      onViewDevices: () => navCtrl.changeIndex(1),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _RecentAlertsSection(
                      alerts: recentAlerts,
                      isLoading: alertCtrl.isLoading.value,
                      onViewAlerts: () => navCtrl.changeIndex(2),
                      onRefresh: alertCtrl.refreshAlert,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Future<void> _refreshHome(
    DeviceController deviceCtrl,
    AlertController alertCtrl,
  ) async {
    await Future.wait([deviceCtrl.refreshDevices(), alertCtrl.refreshAlert()]);
  }
}

class _Header extends StatelessWidget {
  final String name;
  final bool isDark;

  const _Header({required this.name, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.directions_car, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xin chào, $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tổng quan an toàn xe theo thời gian thực',
                style: TextStyle(
                  color: isDark ? Colors.white60 : AppColors.muted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        GetBuilder<ThemeController>(
          builder: (tc) => IconButton.filledTonal(
            tooltip: 'Đổi giao diện',
            onPressed: tc.toggleTheme,
            icon: Icon(tc.isDarkMode ? Icons.light_mode : Icons.dark_mode),
          ),
        ),
      ],
    );
  }
}

class _SafetyPanel extends StatelessWidget {
  final DeviceController controller;

  const _SafetyPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = controller.devices.length;
    final parked = controller.devices
        .where((d) => d.vehicleStatus == VehicleStatus.parked)
        .length;
    final moving = controller.devices
        .where((d) => d.vehicleStatus == VehicleStatus.moving)
        .length;
    final stolen = controller.devices
        .where((d) => d.vehicleStatus == VehicleStatus.stolen)
        .length;
    final buzzerOn = controller.devices.where((d) => d.buzzerStatus).length;
    final riskCount = moving + stolen;
    final hasRisk = riskCount > 0 || buzzerOn > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: hasRisk ? AppColors.danger : AppColors.primary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: (hasRisk ? AppColors.danger : AppColors.primary)
                  .withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasRisk ? Icons.warning_amber_rounded : Icons.verified_user,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasRisk ? 'Cần kiểm tra xe' : 'Tất cả đang ổn',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            total == 0
                ? 'Bạn chưa có thiết bị nào được kích hoạt.'
                : '$parked xe đang đỗ, $moving xe đang di chuyển, $stolen xe nguy hiểm, $buzzerOn còi đang bật.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(label: 'Thiết bị', value: '$total'),
              ),
              Expanded(
                child: _SummaryItem(label: 'An toàn', value: '$parked'),
              ),
              Expanded(
                child: _SummaryItem(label: 'Cần kiểm tra', value: '$riskCount'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onDevices;
  final VoidCallback onAlerts;

  const _QuickActions({required this.onDevices, required this.onAlerts});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: _ActionTile(
              icon: Icons.devices_other,
              label: 'Thiết bị',
              onTap: onDevices,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionTile(
              icon: Icons.notifications_active_outlined,
              label: 'Cảnh báo',
              color: AppColors.danger,
              onTap: onAlerts,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.white38 : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiskDevicesSection extends StatelessWidget {
  final List<Device> devices;
  final int totalDevices;
  final VoidCallback onViewDevices;

  const _RiskDevicesSection({
    required this.devices,
    required this.totalDevices,
    required this.onViewDevices,
  });

  @override
  Widget build(BuildContext context) {
    final visibleDevices = devices.take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Xe cần kiểm tra',
            actionLabel: 'Tất cả',
            onAction: onViewDevices,
          ),
          const SizedBox(height: 10),
          if (totalDevices == 0)
            _EmptyPanel(
              icon: Icons.add_circle_outline,
              title: 'Chưa có thiết bị',
              message: 'Kích hoạt thiết bị trong tab Thiết bị để bắt đầu.',
              actionLabel: 'Mở Thiết bị',
              onAction: onViewDevices,
            )
          else if (visibleDevices.isEmpty)
            _EmptyPanel(
              icon: Icons.verified_user_outlined,
              title: 'Không có xe cần kiểm tra',
              message: 'Các xe đang ở trạng thái an toàn.',
              actionLabel: 'Xem thiết bị',
              onAction: onViewDevices,
            )
          else
            ...visibleDevices.map(
              (device) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RiskDeviceCard(device: device),
              ),
            ),
        ],
      ),
    );
  }
}

class _RiskDeviceCard extends StatelessWidget {
  final Device device;

  const _RiskDeviceCard({required this.device});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = _statusInfo();
    final title = device.licensePlate?.trim().isNotEmpty == true
        ? device.licensePlate!
        : device.deviceId;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.to(() => DeviceDetailScreen(device: device)),
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      status.label,
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
              Text(
                timeago.format(device.lastSeen, locale: 'vi'),
                style: TextStyle(
                  color: isDark ? Colors.white54 : AppColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _RiskStatus _statusInfo() {
    if (device.vehicleStatus == VehicleStatus.stolen) {
      return const _RiskStatus(
        label: 'Xe đang ở trạng thái nguy hiểm',
        icon: Icons.warning_amber_rounded,
        color: AppColors.danger,
      );
    }
    if (device.buzzerStatus) {
      return const _RiskStatus(
        label: 'Còi báo động đang bật',
        icon: Icons.volume_up,
        color: AppColors.danger,
      );
    }
    return const _RiskStatus(
      label: 'Xe đang di chuyển',
      icon: Icons.directions_car,
      color: AppColors.warning,
    );
  }
}

class _RecentAlertsSection extends StatelessWidget {
  final List<Alert> alerts;
  final bool isLoading;
  final VoidCallback onViewAlerts;
  final Future<void> Function() onRefresh;

  const _RecentAlertsSection({
    required this.alerts,
    required this.isLoading,
    required this.onViewAlerts,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Cảnh báo gần đây',
            actionLabel: 'Lịch sử',
            onAction: onViewAlerts,
          ),
          const SizedBox(height: 10),
          if (isLoading && alerts.isEmpty)
            const SizedBox(
              height: 96,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (alerts.isEmpty)
            _EmptyPanel(
              icon: Icons.notifications_none_outlined,
              title: 'Chưa có cảnh báo',
              message: 'Cảnh báo chống trộm sẽ xuất hiện tại đây.',
              actionLabel: 'Làm mới',
              onAction: onRefresh,
            )
          else
            ...alerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CompactAlertCard(alert: alert),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompactAlertCard extends StatelessWidget {
  final Alert alert;

  const _CompactAlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = alert.licensePlate?.trim().isNotEmpty == true
        ? alert.licensePlate!
        : alert.deviceCode;
    final isHigh =
        alert.severity?.toLowerCase() == 'high' ||
        alert.vehicleStatus?.toLowerCase() == 'stolen';
    final color = isHigh ? AppColors.danger : AppColors.warning;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.to(() => AlertDetailScreen(alert: alert)),
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.warning_amber_rounded, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          timeago.format(alert.createdAt, locale: 'vi'),
                          style: TextStyle(
                            color: isDark ? Colors.white54 : AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      alert.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppColors.ink,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.primary),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white60 : AppColors.muted),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _RiskStatus {
  final String label;
  final IconData icon;
  final Color color;

  const _RiskStatus({
    required this.label,
    required this.icon,
    required this.color,
  });
}
