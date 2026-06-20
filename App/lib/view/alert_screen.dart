import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_project/controller/alert_controller.dart';
import 'package:mobile_project/controller/device_controller.dart';
import 'package:mobile_project/models/alert.dart';
import 'package:mobile_project/utils/app_themes.dart';
import 'package:mobile_project/view/alert_detail_screen.dart';
import 'package:mobile_project/view/widgets/custom_search_bar.dart';
import 'package:mobile_project/view/widgets/date_filter_bar.dart';
import 'package:mobile_project/view/widgets/device_filter_bar.dart';
import 'package:timeago/timeago.dart' as timeago;

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  static const int _pageSize = 8;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final alertController = Get.find<AlertController>();
    final deviceController = Get.find<DeviceController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Cảnh báo'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: () async {
              setState(() => _page = 0);
              await alertController.refreshAlert();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(
        () => RefreshIndicator(
          onRefresh: () async {
            setState(() => _page = 0);
            await alertController.refreshAlert();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _AlertSummary(controller: alertController),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: DateFilterBar(
                    selectedDate: alertController.selectedDate.value,
                    onDateSelected: (date) {
                      setState(() => _page = 0);
                      alertController.setDate(date);
                    },
                    onClear: () {
                      setState(() => _page = 0);
                      alertController.setDate(null);
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: DeviceFilterBar(
                    devices: deviceController.devices,
                    selectedDeviceId: alertController.selectedDeviceId.value,
                    onChanged: (deviceId) {
                      setState(() => _page = 0);
                      alertController.setDevice(deviceId);
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: CustomSearchBar(
                  initialText: alertController.searchText.value,
                  hintText: 'Tìm theo thiết bị hoặc nội dung',
                  onSearch: (value) {
                    setState(() => _page = 0);
                    alertController.search(value);
                  },
                ),
              ),
              if (alertController.isLoading.value)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (alertController.error.value != null &&
                  alertController.alert.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _StateMessage(
                    icon: Icons.verified_user_outlined,
                    title: 'Chưa có cảnh báo',
                    message:
                        'Khi xe di chuyển bất thường, cảnh báo sẽ xuất hiện ở đây.',
                    actionLabel: 'Làm mới',
                    onAction: () async {
                      setState(() => _page = 0);
                      await alertController.fetchAlert();
                    },
                  ),
                )
              else if (alertController.filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _StateMessage(
                    icon:
                        alertController.selectedDate.value == null &&
                            alertController.selectedDeviceId.value == null
                        ? Icons.search_off
                        : Icons.event_busy_outlined,
                    title:
                        alertController.selectedDate.value == null &&
                            alertController.selectedDeviceId.value == null
                        ? 'Không tìm thấy cảnh báo'
                        : 'Không có cảnh báo phù hợp',
                    message:
                        alertController.selectedDate.value == null &&
                            alertController.selectedDeviceId.value == null
                        ? 'Thử tìm bằng mã thiết bị hoặc nội dung khác.'
                        : 'Chọn ngày, thiết bị khác hoặc xóa bộ lọc.',
                    actionLabel:
                        alertController.selectedDate.value == null &&
                            alertController.selectedDeviceId.value == null
                        ? 'Xóa tìm kiếm'
                        : 'Xóa bộ lọc',
                    onAction: () {
                      setState(() => _page = 0);
                      if (alertController.selectedDate.value == null &&
                          alertController.selectedDeviceId.value == null) {
                        alertController.search('');
                      } else {
                        alertController.clearFilters();
                      }
                    },
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: _PagedAlertList(
                    alerts: alertController.filtered,
                    pageSize: _pageSize,
                    currentPage: _page,
                    onPageChanged: (page) => setState(() => _page = page),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PagedAlertList extends StatelessWidget {
  final List<Alert> alerts;
  final int pageSize;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const _PagedAlertList({
    required this.alerts,
    required this.pageSize,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = ((alerts.length - 1) ~/ pageSize) + 1;
    final page = currentPage >= totalPages ? totalPages - 1 : currentPage;
    final start = page * pageSize;
    final end = (start + pageSize) > alerts.length
        ? alerts.length
        : start + pageSize;
    final pageItems = alerts.sublist(start, end);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        children: [
          _PaginationBar(
            startIndex: start,
            endIndex: end,
            totalItems: alerts.length,
            currentPage: page,
            totalPages: totalPages,
            onPrevious: page == 0 ? null : () => onPageChanged(page - 1),
            onNext: page >= totalPages - 1
                ? null
                : () => onPageChanged(page + 1),
          ),
          const SizedBox(height: 10),
          ...pageItems.map(
            (alert) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AlertCard(alert: alert),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int startIndex;
  final int endIndex;
  final int totalItems;
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _PaginationBar({
    required this.startIndex,
    required this.endIndex,
    required this.totalItems,
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${startIndex + 1}-$endIndex / $totalItems cảnh báo',
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Trang trước',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            '${currentPage + 1}/$totalPages',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          IconButton(
            tooltip: 'Trang sau',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _AlertSummary extends StatelessWidget {
  final AlertController controller;

  const _AlertSummary({required this.controller});

  @override
  Widget build(BuildContext context) {
    final latest = controller.alert.isEmpty ? null : controller.alert.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        width: double.infinity,
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${controller.alert.length} cảnh báo',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    latest == null
                        ? 'Chưa ghi nhận cảnh báo mới'
                        : "Mới nhất: ${timeago.format(latest.createdAt, locale: 'vi')}",
                    style: TextStyle(
                      color: isDark ? Colors.white60 : AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Alert alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = alert.licensePlate?.trim().isNotEmpty == true
        ? alert.licensePlate!
        : alert.deviceCode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Get.to(() => AlertDetailScreen(alert: alert)),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.danger,
                ),
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
                              fontSize: 17,
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
                    const SizedBox(height: 6),
                    Text(
                      alert.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppColors.ink,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(icon: Icons.memory, label: alert.deviceCode),
                        if (alert.speed != null)
                          _InfoChip(
                            icon: Icons.speed,
                            label: '${alert.speed!.toStringAsFixed(1)} km/h',
                            color: AppColors.danger,
                          ),
                        if (alert.hasLocation)
                          const _InfoChip(
                            icon: Icons.location_on_outlined,
                            label: 'Có vị trí',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
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
