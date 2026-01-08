import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mobile_project/models/alert.dart';
import 'package:mobile_project/utils/app_textstyles.dart';
import 'package:mobile_project/view/alert_detail_screen.dart';
import 'package:mobile_project/view/widgets/custom_search_bar.dart';

import '../controller/alert_controller.dart';

class AlertScreen extends StatelessWidget {
  const AlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alertController = Get.find<AlertController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Danh sách thông báo',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: Obx(
            () => RefreshIndicator(
          onRefresh: alertController.refreshAlert,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Summary
              SliverToBoxAdapter(
                child: _buildSummarySection(context),
              ),

              // Search bar
              SliverToBoxAdapter(
                child: CustomSearchBar(
                  initialText: alertController.searchText.value,
                  onSearch: alertController.search,
                ),
              ),

              // List alert
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final alert = alertController.filtered[index];
                      return _buildAlertItem(context, alert);
                    },
                    childCount: alertController.filtered.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alertController = Get.find<AlertController>();

    return Obx(
          () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[100],
          borderRadius:
          const BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        child: Text(
          'Tổng: ${alertController.alert.length} thông báo',
          style: AppTextStyle.withColor(
            AppTextStyle.h2,
            Theme.of(context).textTheme.bodyLarge!.color!,
          ),
        ),
      ),
    );
  }

  Widget _buildAlertItem(BuildContext context, Alert alert) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AlertDetailScreen(alert: alert),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message
            Text(
              alert.message,
              style: AppTextStyle.withColor(
                AppTextStyle.h3,
                Theme.of(context).textTheme.bodyLarge!.color!,
              ),
            ),
            const SizedBox(height: 4),

            // Device ID + license plate
            Text(
              "Device ID: ${alert.deviceCode} \nBiển số: ${alert.licensePlate ?? 'Chưa có'}",
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),

            // Created time
            Text(
              "Thời gian: ${alert.createdAt != null
                  ? DateFormat('dd/MM/yyyy').format(alert.createdAt)
                  : 'Chưa kích hoạt'}",
              style: TextStyle(
                color: isDark ? Colors.greenAccent : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
