import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_project/controller/auth_controller.dart';
import 'package:mobile_project/utils/app_textstyles.dart';
import 'package:mobile_project/view/widgets/custom_textfield.dart';

class ProfileForm extends StatelessWidget {
  ProfileForm({super.key});

  final AuthController authController = Get.find<AuthController>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _nameController.text = authController.user.value?.name ?? '';
    _emailController.text = authController.user.value?.email ?? '';
    _phoneController.text = authController.user.value?.phone ?? '';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: isDark ?
                      Colors.black.withValues(alpha:0.2 ):
                      Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            ),
            child: CustomTextfield(
              label: 'Name',
              prefixIcon: Icons.person_outline,
              controller: _nameController,
            ),
          ),
          const SizedBox(height:16 ,),

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: isDark ?
                    Colors.black.withValues(alpha:0.2 ):
                    Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                )
              ]
            ),
            child:  CustomTextfield(
              label: 'Email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              controller: _emailController,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isDark ?
                    Colors.black.withValues(alpha:0.2 ):
                    Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ]
            ),
            child: CustomTextfield(
              label: 'Phone Number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              controller: _phoneController,
            ),
          ),
          const SizedBox(height: 32,),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                  bool success = await authController.updateProfile(
                    _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
                    _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
                    _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
                  );

                  if (success) {
                    Get.back();
                    Get.snackbar(
                      "Update Success",
                      "Profile has been updated",
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  } else {
                    Get.snackbar(
                      "Update Failed",
                      "Please try again",
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }

              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                )
              ),
              child: Text(
                'Save Changes',
                style: AppTextStyle.withColor(
                  AppTextStyle.buttonMedium,
                  Colors.white,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
