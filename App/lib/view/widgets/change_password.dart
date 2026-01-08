import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_project/controller/auth_controller.dart';
import 'package:mobile_project/controller/device_controller.dart';
import 'package:mobile_project/utils/app_textstyles.dart';
import 'package:mobile_project/view/widgets/custom_textfield.dart';

class ChangePassword extends StatelessWidget {
  ChangePassword({super.key});

  final AuthController _authController = AuthController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Change Password',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===== old password =====
                CustomTextfield(
                  label: 'Old Password',
                  prefixIcon: Icons.lock_outline,
                  keyboardType: TextInputType.visiblePassword ,
                  isPassword: true,
                  controller: _oldPasswordController,
                  validator: (value){
                    if(value == null || value.isEmpty){
                      return 'Please enter your old password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ===== New password =====
                Container(
                  decoration: _boxDecoration(context, isDark),
                  child: CustomTextfield(
                    label: 'New Password',
                    prefixIcon: Icons.lock_outline,
                    keyboardType: TextInputType.visiblePassword ,
                    isPassword: true,
                    controller: _newPasswordController,
                    validator: (value){
                      if(value == null || value.isEmpty){
                        return 'Please enter your new password';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // ===== Confirm Password =====
                Container(
                  decoration: _boxDecoration(context, isDark),
                  child: CustomTextfield(
                    label: 'Confirm New Password',
                    prefixIcon: Icons.lock_outline,
                    keyboardType: TextInputType.visiblePassword ,
                    isPassword: true,
                    controller: _confirmPasswordController,
                    validator: (value){
                      if(value == null || value.isEmpty){
                        return 'Please confirm your new password';
                      }
                      if(value != _newPasswordController.text){
                        return 'New Password do not match';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // ===== Save Button =====
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        // // tất cả field hợp lệ → gọi api
                         bool success = await _authController.changePassword(
                           _oldPasswordController.text.trim(),
                           _newPasswordController.text.trim()
                         );


                        if (success) {
                          Get.back(); // quay về
                          Get.snackbar(
                            "SUCCESS",
                            "Change Password Success",
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        } else {
                          Get.snackbar(
                            "FAILED",
                            "Change Password Failed",

                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Save Changes',
                      style: AppTextStyle.withColor(
                        AppTextStyle.buttonMedium,
                        Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ),
      ),
    );
  }

  BoxDecoration _boxDecoration(BuildContext context, bool isDark) {
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
