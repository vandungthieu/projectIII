import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_project/controller/auth_controller.dart';
import 'package:mobile_project/controller/device_controller.dart';
import 'package:mobile_project/controller/theme_controller.dart';
import 'package:mobile_project/models/device.dart';
import 'package:mobile_project/utils/app_themes.dart';
import 'package:mobile_project/view/device_detail_screen.dart';
import 'package:mobile_project/view/widgets/device_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceCtrl = Get.find<DeviceController>();
    final authCtrl = Get.find<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Obx(
          () => RefreshIndicator(
            onRefresh: deviceCtrl.refreshDevices,
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Xe của bạn',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: deviceCtrl.refreshDevices,
                          child: const Text('Làm mới'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (deviceCtrl.isLoading.value)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (deviceCtrl.error.value != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _StateMessage(
                      icon: Icons.wifi_off,
                      title: 'Không tải được dữ liệu',
                      message: deviceCtrl.error.value!,
                      actionLabel: 'Thử lại',
                      onAction: deviceCtrl.fetchDevices,
                    ),
                  )
                else if (deviceCtrl.devices.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _StateMessage(
                      icon: Icons.add_circle_outline,
                      title: 'Chưa có thiết bị',
                      message: 'Kích hoạt thiết bị để bắt đầu theo dõi xe.',
                      actionLabel: 'Làm mới',
                      onAction: deviceCtrl.fetchDevices,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final device = deviceCtrl.devices[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == deviceCtrl.devices.length - 1
                                ? 0
                                : 12,
                          ),
                          child: DeviceCard(
                            device: device,
                            onTap: () => Get.to(
                              () => DeviceDetailScreen(device: device),
                            ),
                          ),
                        );
                      }, childCount: deviceCtrl.devices.length),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
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
                'Theo dõi trạng thái xe theo thời gian thực',
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
