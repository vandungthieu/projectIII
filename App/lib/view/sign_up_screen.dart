import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_project/utils/app_textstyles.dart';
import 'package:mobile_project/view/signin_screen.dart';
import 'package:mobile_project/view/widgets/custom_textfield.dart';

import '../controller/auth_controller.dart';

class SignUpScreen extends StatelessWidget {
  SignUpScreen({super.key});

  final authController = Get.find<AuthController>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                    onPressed: ()=> Get.back() ,
                    icon: Icon (
                      Icons.arrow_back,
                      color : isDark ?  Colors.white: Colors.black,
                    )
                ),

                const SizedBox(height: 20,),
                Text(
                  'Create Account',
                  style: AppTextStyle.withColor(
                    AppTextStyle.h1,
                    Theme.of(context).textTheme.bodyLarge!.color!,
                  ),
                ),

                const SizedBox(height: 8,),

                Text(
                  'Signup to get started',
                  style: AppTextStyle.withColor(
                    AppTextStyle.bodyLarge,
                    isDark ?  Colors.grey[400]!: Colors.grey[600]!,
                  ),
                ),

                const SizedBox(height: 40,),


                const SizedBox(height: 16,),

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

                const SizedBox(height: 16,),

                // email textfield
                CustomTextfield(
                  label: 'Email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress ,
                  controller: _emailController,
                  validator: (value){
                    if(value == null || value.isEmpty){
                      return 'Please enter your email';
                    }
                    if(!GetUtils.isEmail(value)){
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16,),

                // password textfield
                CustomTextfield(
                  label: 'Password',
                  prefixIcon: Icons.lock_outline,
                  keyboardType: TextInputType.visiblePassword ,
                  isPassword: true,
                  controller: _passwordController,
                  validator: (value){
                    if(value == null || value.isEmpty){
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16,),

                // confirm password textfield
                CustomTextfield(
                  label: 'Confirm Password',
                  prefixIcon: Icons.lock_outline,
                  keyboardType: TextInputType.visiblePassword ,
                  isPassword: true,
                  controller: _confirmPasswordController,
                  validator: (value){
                    if(value == null || value.isEmpty){
                      return 'Please confirm your password';
                    }
                    if(value != _passwordController.text){
                      return 'Password do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24,),

                // signup button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          // tất cả field hợp lệ → gọi register
                          bool success = await authController.register(
                            _usernameController.text.trim(),
                            _passwordController.text.trim(),
                            _emailController.text.trim(),
                          );

                          if (success) {
                            Get.back(); // quay về LoginScreen sau khi đăng ký
                            Get.snackbar(
                              "Register Success",
                              "You can now login with your account",
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          } else {
                            Get.snackbar(
                              "Register Failed",
                              "Username or email may already exist",
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          )
                      ),
                      child: Text(
                        'Sign up',
                        style: AppTextStyle.withColor(
                          AppTextStyle.buttonMedium,
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                  ),
                ),
                const SizedBox(height: 24,),

                // signin textbutton
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: AppTextStyle.withColor(
                        AppTextStyle.bodyMedium,
                        isDark ? Colors.grey[400]! : Colors.grey[600]!,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Get.off(
                            () => SigninScreen(),
                      ),
                      child: Text(
                        'Sign In',
                        style: AppTextStyle.withColor(
                          AppTextStyle.buttonMedium,
                          Theme.of(context).primaryColor,
                        ),
                      ) ,
                    )
                  ],
                )

              ],
            ),
          ),
        ),
      )
    );
  }
}
