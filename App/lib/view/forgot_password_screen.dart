import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_project/utils/app_textstyles.dart';
import 'package:mobile_project/view/widgets/custom_textfield.dart';

import 'email_input_screen.dart';

class ForgotPasswordScreen extends StatelessWidget {
  ForgotPasswordScreen({super.key});

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24) ,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // back button
                IconButton(
                    onPressed: ()=> Get.back() ,
                    icon: Icon (
                      Icons.arrow_back,
                      color : isDark ?  Colors.white: Colors.black,
                    )
                ),

                const SizedBox(height: 20,),
                // reset password
                Text(
                  'Reset Password',
                  style: AppTextStyle.withColor(
                    AppTextStyle.h1,
                    Theme.of(context).textTheme.bodyLarge!.color!,
                  ) ,
                ),

                const SizedBox(height: 8,),
                Text(
                  'Enter your username to reset password',
                  style: AppTextStyle.withColor(
                    AppTextStyle.bodyLarge,
                    isDark ? Colors.grey[400]! : Colors.grey[600]!,
                  ) ,
                ),
                const SizedBox(height: 40,),

                // username textfield
                CustomTextfield(
                  label: 'Username',
                  prefixIcon: Icons.person_outline,
                  keyboardType: TextInputType.text ,
                  controller: _usernameController,
                  validator: (value){
                    if(value == null || value.isEmpty){
                      return 'Please enter your username';
                    }
                    if(!GetUtils.isUsername(value)){
                      return 'Please enter a valid username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24,),

                //button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Get.to(() => EmailInputScreen());
                      }
                    },

                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        )
                    ),
                    child: Text(
                      'Continue',
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
      ),
    );
  }
}
