import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_project/controller/device_controller.dart';
import 'package:mobile_project/controller/theme_controller.dart';
import 'package:mobile_project/view/widgets/device_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject controller
    final DeviceController deviceCtrl = Get.find<DeviceController>();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Obx(() => RefreshIndicator(
          onRefresh: deviceCtrl.refreshDevices,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= HEADER =================
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blueGrey,
                        child: Text(
                          'u'.toUpperCase(),
                          style: const TextStyle(fontSize: 24, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào!',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const Text(
                            'Good Morning',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Nút đổi theme
                      GetBuilder<ThemeController>(
                        builder: (tc) => IconButton(
                          onPressed: tc.toggleTheme,
                          icon: Icon(
                            tc.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                            color: isDark ? Colors.yellow : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ================= TIÊU ĐỀ DANH SÁCH =================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Xe của bạn",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ================= DANH SÁCH THIẾT BỊ =================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(16),
                      color: isDark ? Colors.grey[900] : Colors.grey[50],
                    ),
                    child: _buildDeviceList(deviceCtrl),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildDeviceList(DeviceController ctrl) {
    if (ctrl.isLoading.value) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (ctrl.error.value != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(ctrl.error.value!),
              TextButton(
                onPressed: ctrl.fetchDevices,
                child: const Text("Thử lại"),
              ),
            ],
          ),
        ),
      );
    }

    if (ctrl.devices.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            "Bạn chưa có thiết bị nào\nKéo xuống để làm mới",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ctrl.devices.length,
      itemBuilder: (context, index) {
        final device = ctrl.devices[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DeviceCard(device: device),
        );
      },
    );
  }
}