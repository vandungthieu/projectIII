import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_project/controller/auth_controller.dart';
import 'package:mobile_project/utils/app_textstyles.dart';
import 'package:mobile_project/view/device_screen.dart';
import 'package:mobile_project/view/edit_profile_screen.dart';
import 'package:mobile_project/view/setting_screen.dart';
import 'package:mobile_project/view/signin_screen.dart';
import 'package:mobile_project/view/widgets/change_password.dart';

class AccountScreen extends StatelessWidget {
  AccountScreen({super.key});

  final AuthController authCtrl = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Account',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Get.to(SettingScreen()),
            icon: Icon(
              Icons.settings_outlined,
              color: isDark ? Colors.white : Colors.black,
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileSection(context),
            const SizedBox(height: 24,),
            _buildMenuSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context){
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: authCtrl.fetchUserInfo,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Obx(() {
          final user = authCtrl.user.value;

          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blueGrey,
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : "?",
                  style: const TextStyle(fontSize: 48, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),

              // Name
              Text(
                user.displayName,
                style: AppTextStyle.withColor(
                  AppTextStyle.h2,
                  Theme.of(context).textTheme.bodyLarge!.color!,
                ),
              ),
              const SizedBox(height: 4),

              // Email
              Text(
                user.email,
                style: AppTextStyle.withColor(
                  AppTextStyle.bodyMedium,
                  isDark ? Colors.grey[400]! : Colors.grey[600]!,
                ),
              ),
              const SizedBox(height: 8),

              // Phone
              if (user.phone != null && user.phone!.isNotEmpty)
                Text(
                  user.phone!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[500] : Colors.grey[700],
                  ),
                ),

              const SizedBox(height: 16),

              // Edit Profile
              OutlinedButton(
                onPressed: () => Get.to(() => EditProfileScreen()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  side: BorderSide(
                    color: isDark ? Colors.white70 : Colors.black26,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Chỉnh sửa hồ sơ',
                  style: AppTextStyle.withColor(
                    AppTextStyle.buttonMedium,
                    Theme.of(context).textTheme.bodyLarge!.color!,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );

  }

  Widget _buildMenuSection(BuildContext context){
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final menuItems = [
      {'icon': Icons.device_hub_outlined, 'title' : 'Devices'},
      {'icon': Icons.help_outlined, 'title' : 'Help Center'},
      {'icon': Icons.password_outlined, 'title' : 'Change Password'},
      {'icon': Icons.logout_outlined, 'title' : 'Logout'},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal:  16),
      child: Column(
        children: menuItems.map((item){
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                  blurRadius : 8,
                  offset : const Offset(0, 2),
                )
              ]
            ),
          child: ListTile(
            leading: Icon(
              item['icon'] as IconData,
              color:  Theme.of(context).primaryColor,
            ),
            title: Text(
              item['title'] as String,
              style:  AppTextStyle.withColor(
                AppTextStyle.buttonMedium,
                Theme.of(context).textTheme.bodyLarge!.color!,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[400]: Colors.grey[600],
            ),
            onTap: (){
              if(item['title'] == 'Logout'){
                _showLogoutDialog(context);
              } else if(item['title'] == 'Devices'){
                Get.to(DeviceScreen());
              }else if(item['title'] == 'Help Center'){
                // navigation to help center
              }else if(item['title'] == 'Change Password'){
                  Get.to(ChangePassword());
              }
            },
          ),
          );
        }).toList()
      ),
    );
  }

  void _showLogoutDialog(BuildContext context){
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),

        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape:  BoxShape.circle,
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Theme.of(context).primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 8,),
            Text(
              'Are you sure want to logout',
              style: AppTextStyle.withColor(
                AppTextStyle.bodyMedium,
                isDark ? Colors.grey[400] ! : Colors.grey[600]!,
              ),
            ),
            const SizedBox(height: 24,),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48), // chiều cao nút
                      side: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTextStyle.withColor(
                        AppTextStyle.buttonMedium,
                        Theme.of(context).textTheme.bodyLarge!.color!,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12), // giảm từ 16 xuống 12

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final AuthController authController = Get.find<AuthController>();
                      authController.logout();
                      Get.offAll(() => SigninScreen());
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48), // chiều cao nút
                      backgroundColor: Theme.of(context).primaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Logout',
                      style: AppTextStyle.withColor(
                        AppTextStyle.buttonMedium,
                        Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            )

          ],
        ),
      )
    );
  }
}
