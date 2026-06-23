import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_project/controller/device_controller.dart';
import 'package:mobile_project/utils/app_textstyles.dart';
import 'package:mobile_project/view/widgets/custom_textfield.dart';

class ActiveDeviceScreen extends StatelessWidget {
  ActiveDeviceScreen({super.key});

  final TextEditingController _deviceIdController = TextEditingController();
  final TextEditingController _deviceKeyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Kích hoạt thiết bị",
          style: AppTextStyle.withColor(
            AppTextStyle.h2,
            Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Nhập thông tin thiết bị của bạn",
                  style: AppTextStyle.withColor(
                    AppTextStyle.h3,
                    Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.black,
                  ),
                ),

                const SizedBox(height: 24),

                // Device ID
                Text(
                  "Mã thiết bị",
                  style: AppTextStyle.withColor(
                    AppTextStyle.buttonMedium,
                    Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.black,
                  ),
                ),
                const SizedBox(height: 8),

                CustomTextfield(
                  label: 'Nhập mã thiết bị',
                  prefixIcon: Icons.badge_outlined,
                  keyboardType: TextInputType.text,
                  controller: _deviceIdController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mã thiết bị';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Device Key
                Text(
                  "Khóa thiết bị",
                  style: AppTextStyle.withColor(
                    AppTextStyle.buttonMedium,
                    Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.black,
                  ),
                ),
                const SizedBox(height: 8),

                CustomTextfield(
                  label: 'Nhập khóa thiết bị',
                  prefixIcon: Icons.key_outlined,
                  keyboardType: TextInputType.text,
                  controller: _deviceKeyController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập khóa thiết bị';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 180,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final id = _deviceIdController.text.trim();
                          final key = _deviceKeyController.text.trim();

                          Get.find<DeviceController>().activateDevice(id, key);
                        }
                      },
                      child: Text(
                        "Kích hoạt thiết bị",
                        style: AppTextStyle.buttonMedium,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
