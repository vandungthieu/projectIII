import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_project/models/device.dart';
import 'package:mobile_project/utils/app_textstyles.dart';
import 'package:mobile_project/view/active_device_screen.dart';
import 'package:mobile_project/view/device_detail_screen.dart';
import 'package:mobile_project/view/widgets/custom_search_bar.dart';

import '../controller/device_controller.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final deviceController = Get.find<DeviceController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Danh sách thiết bị',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: Obx(
            () => CustomScrollView(
          slivers: [
            // Summary
            SliverToBoxAdapter(
              child: _buildSummarySection(context),
            ),

            SliverToBoxAdapter(
              child: CustomSearchBar(
                initialText: deviceController.searchText.value,
                onSearch: deviceController.search,
              ),
            ),

            // List devices
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    // SỬA: Dùng filtered list thay vì devices list
                    final device = deviceController.filtered[index];
                    return _buildDeviceItem(context, device);
                  },
                  childCount: deviceController.filtered.length,
                ),
              ),
            )
          ],
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            Get.to(() => ActiveDeviceScreen());
          },
          child: Text("Active Device"),
        ),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceController = Get.find<DeviceController>();

    return Obx(
          () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[100],
          borderRadius:
          const BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        child: Text(
          'Tổng: ${deviceController.devices.length} | Hiển thị: ${deviceController.filtered.length}',
          style: AppTextStyle.withColor(
            AppTextStyle.h2,
            Theme.of(context).textTheme.bodyLarge!.color!,
          ),
        ),
      ),
    );
  }

  // UI cho từng device
  Widget _buildDeviceItem(BuildContext context, Device device) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        // Điều hướng tới màn hình chi tiết
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DeviceDetailScreen(device: device),
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
            Text(
              device.deviceId ?? "Device ID",
              style: AppTextStyle.withColor(
                AppTextStyle.h3,
                Theme.of(context).textTheme.bodyLarge!.color!,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Biển số: ${device.licensePlate}",
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Trạng thái: ${device.vehicleStatus.name}",
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
