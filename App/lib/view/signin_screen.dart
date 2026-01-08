import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_project/controller/auth_controller.dart';
import 'package:mobile_project/utils/app_textstyles.dart';
import 'package:mobile_project/view/forgot_password_screen.dart';
import 'package:mobile_project/view/main_screen.dart';
import 'package:mobile_project/view/sign_up_screen.dart';
import 'package:mobile_project/view/widgets/custom_textfield.dart';

class SigninScreen extends StatelessWidget {
  SigninScreen({super.key});

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;


    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key:  _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                Text(
                  'Welcome',
                  style: AppTextStyle.withColor(AppTextStyle.h1, Theme.of(context).textTheme.bodyLarge!.color!),
                ),
                const SizedBox(height: 8),
                Text(
                    'Sign in to continue',
                    style: AppTextStyle.withColor(
                      AppTextStyle.bodyLarge,
                      isDark ? Colors.grey[400]! : Colors.grey[600]!,
                    )

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
                SizedBox(height: 16,),

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

                const SizedBox(height: 8,),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                      onPressed: () => Get.to(() =>  ForgotPasswordScreen()),
                      child: Text(
                          'Forgot Password?',
                          style: AppTextStyle.withColor(
                              AppTextStyle.buttonMedium,
                              Theme.of(context).primaryColor
                          )
                      )
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // <-- Validate trước khi login
                      if (_formKey.currentState!.validate()) {
                        _handleSignIn();
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
                      'Sign In',
                      style: AppTextStyle.withColor(
                        AppTextStyle.buttonMedium,
                        Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24,),
                // sign up textbutton
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text (
                      "Don't have an account?",
                      style: AppTextStyle.withColor(
                          AppTextStyle.buttonMedium,
                          isDark ? Colors.grey[400]! : Colors.grey[600]!
                      ),
                    ),
                    TextButton(
                      onPressed: () => Get.to(()=>  SignUpScreen()),
                      child: Text(
                        'Sign up',
                        style: AppTextStyle.withColor(
                          AppTextStyle.buttonMedium,
                          Theme.of(context).primaryColor,
                        ),
                      ),

                    )
                  ],
                )
              ],
            ),
          ),
        )
      )
    );
  }

  // sign in button onpressed
  void _handleSignIn() async {
       final AuthController authController = Get.find<AuthController>();

       // Lấy dữ liệu từ TextField
       String username = _usernameController.text.trim();
       String password = _passwordController.text.trim();

       // Gọi login async
       bool success = await authController.login(username, password);

       if (success) {
         // Nếu đăng nhập thành công → chuyển sang MainScreen
         Get.off(() => const MainScreen());
       } else {
         // Nếu đăng nhập thất bại → hiển thị lỗi
         Get.snackbar(
           "Login Failed",
           "Invalid username or password",
           snackPosition: SnackPosition.BOTTOM,
         );
       }
  }
}