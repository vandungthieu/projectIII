import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_project/controller/device_controller.dart';
import 'package:mobile_project/models/device.dart';
import 'package:mobile_project/utils/app_themes.dart';
import 'package:mobile_project/view/active_device_screen.dart';
import 'package:mobile_project/view/device_detail_screen.dart';
import 'package:mobile_project/view/widgets/custom_search_bar.dart';
import 'package:mobile_project/view/widgets/device_card.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceController = Get.find<DeviceController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Thiết bị'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: deviceController.refreshDevices,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(
        () => RefreshIndicator(
          onRefresh: deviceController.refreshDevices,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _SummarySection(controller: deviceController),
              ),
              SliverToBoxAdapter(
                child: CustomSearchBar(
                  initialText: deviceController.searchText.value,
                  hintText: 'Tìm theo biển số hoặc mã thiết bị',
                  onSearch: deviceController.search,
                ),
              ),
              SliverToBoxAdapter(
                child: _StatusFilters(controller: deviceController),
              ),
              if (deviceController.isLoading.value)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (deviceController.error.value != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _StateMessage(
                    icon: Icons.wifi_off,
                    title: 'Không tải được thiết bị',
                    message: deviceController.error.value!,
                    actionLabel: 'Thử lại',
                    onAction: deviceController.fetchDevices,
                  ),
                )
              else if (deviceController.filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _StateMessage(
                    icon: Icons.search_off,
                    title: 'Không tìm thấy thiết bị',
                    message: 'Thử tìm bằng biển số hoặc mã thiết bị khác.',
                    actionLabel: 'Xóa tìm kiếm',
                    onAction: () => deviceController.search(''),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final device = deviceController.filtered[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == deviceController.filtered.length - 1
                              ? 0
                              : 12,
                        ),
                        child: DeviceCard(
                          device: device,
                          onTap: () =>
                              Get.to(() => DeviceDetailScreen(device: device)),
                        ),
                      );
                    }, childCount: deviceController.filtered.length),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => ActiveDeviceScreen()),
        icon: const Icon(Icons.add),
        label: const Text('Kích hoạt'),
      ),
    );
  }
}

class _StatusFilters extends StatelessWidget {
  final DeviceController controller;

  const _StatusFilters({required this.controller});

  @override
  Widget build(BuildContext context) {
    final filters = [
      const _DeviceFilter(label: 'Tất cả', value: 'all'),
      const _DeviceFilter(label: 'Đang đỗ', value: 'parked'),
      const _DeviceFilter(label: 'Đang chạy', value: 'moving'),
      const _DeviceFilter(label: 'Nguy hiểm', value: 'stolen'),
      const _DeviceFilter(label: 'Còi bật', value: 'buzzer'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters
              .map(
                (filter) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter.label),
                    selected: controller.statusFilter.value == filter.value,
                    onSelected: (_) => controller.setStatusFilter(filter.value),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _DeviceFilter {
  final String label;
  final String value;

  const _DeviceFilter({required this.label, required this.value});
}

class _SummarySection extends StatelessWidget {
  final DeviceController controller;

  const _SummarySection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = controller.devices.length;
    final moving = controller.devices
        .where((d) => d.vehicleStatus == VehicleStatus.moving)
        .length;
    final parked = controller.devices
        .where((d) => d.vehicleStatus == VehicleStatus.parked)
        .length;
    final stolen = controller.devices
        .where((d) => d.vehicleStatus == VehicleStatus.stolen)
        .length;
    final riskCount = moving + stolen;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            _Counter(label: 'Tổng', value: total, color: AppColors.primary),
            _Divider(isDark: isDark),
            _Counter(label: 'An toàn', value: parked, color: AppColors.success),
            _Divider(isDark: isDark),
            _Counter(
              label: 'Cần kiểm tra',
              value: riskCount,
              color: riskCount > 0 ? AppColors.danger : AppColors.warning,
            ),
          ],
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _Counter({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white60 : AppColors.muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;

  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
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
