import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_project/utils/app_textstyles.dart';
import 'package:mobile_project/view/widgets/profile_form.dart';
import 'package:mobile_project/view/widgets/profile_image.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back),
        ),
        title: Text(
            'Edit Profile',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 24,),
            ProfileImage(),
            SizedBox(height: 32,),
            ProfileForm(),
          ],
        ),
      ),
    );
  }
}
