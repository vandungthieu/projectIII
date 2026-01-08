import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_project/utils/app_textstyles.dart';
import 'package:mobile_project/view/widgets/custom_textfield.dart';

class EmailInputScreen extends StatelessWidget {
  EmailInputScreen({super.key});

  final TextEditingController _emailController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key : _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter Email',
                style: AppTextStyle.withColor(
                  AppTextStyle.h1,
                  Theme.of(context).textTheme.bodyLarge!.color!,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Enter your email to receive reset pin',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodyLarge,
                  isDark ? Colors.grey[400]! : Colors.grey[600]!,
                ),
              ),

              const SizedBox(height: 40),

              CustomTextfield(
                label: 'Email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!GetUtils.isEmail(value)) {
                    return 'Invalid email format';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      showSuccessDialog(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      )),
                  child: Text(
                    'Send Reset',
                    style: AppTextStyle.withColor(
                      AppTextStyle.buttonMedium,
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // show success dialog
  void showSuccessDialog(BuildContext context){
    Get.dialog(
      AlertDialog(
        title: Text(
          'Check Your Email',
          style: AppTextStyle.h3,
        ),
        content: Text(
          'We have sent password recovery instruction to your email',
          style: AppTextStyle.buttonMedium,
        ),
        actions: [
          TextButton(
              onPressed:() => Get.back() ,
              child: Text(
                'OK',
                style: AppTextStyle.withColor(
                  AppTextStyle.buttonMedium,
                  Theme.of(context).primaryColor,
                ),
              )
          )
        ],
      )
    );
  }
}


