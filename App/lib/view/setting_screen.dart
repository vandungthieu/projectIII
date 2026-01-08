import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_project/controller/theme_controller.dart';

import '../utils/app_textstyles.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
            onPressed: ()=> Get.back(),
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black,
            )
        ),
        title: Text(
          'Settings',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              'Appearance',
              [
                _buildThemeToggle(context),
              ]
            ),
            _buildSection(
                context,
                'Notification',
                [
                  _builSwitchTite(
                    context,
                    'Push Notification',
                    'Receive push notification',
                    true
                  ),
                  _builSwitchTite(
                      context,
                      'Email Notification',
                      'Receive email updates about your vehicle',
                      false
                  )
                ]
            ),
            
            _buildSection(context, 'Privacy', [
              _buildNavigationTitle(
                context,
                'Privacy Policy',
                'View our privacy policy',
                Icons.privacy_tip_outlined,
              ),
              _buildNavigationTitle(
                context,
                'Term of Service',
                'Read out term of Service',
                Icons.description_outlined,
              )
              ]
            ),

            _buildSection(
              context,
              'About',
              [
                _buildNavigationTitle(context, 'App Version', '1.0.0', Icons.info_outline,)
              ]
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children){
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child:  Text(
            title,
            style: AppTextStyle.withColor(
               AppTextStyle.h3,
               isDark ? Colors.grey[400]! : Colors.grey[600]!,
            ),
          ),
        ),
        ...children
      ],
    );
  }

  Widget _buildThemeToggle(BuildContext context){
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GetBuilder<ThemeController>(
      builder: (controller) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: isDark? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ]
        ),
        child: ListTile(
          leading: Icon(
            controller.isDarkMode? Icons.dark_mode : Icons.light_mode,
            color: Theme.of(context).primaryColor,
          ),
          title: Text(
            'Dark Mode',
            style: AppTextStyle.withColor(
              AppTextStyle.buttonMedium,
              Theme.of(context).textTheme.bodyLarge!.color!,
            ),
          ),
          trailing: Switch.adaptive(
              value: controller.isDarkMode,
              onChanged: (value) => controller.toggleTheme(),
              activeThumbColor: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _builSwitchTite(
      BuildContext context ,
      String title,
      String subtitle,
      bool initialValue,
      ){
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2)
          )
        ]
      ),
      child: ListTile(
        title: Text(
          title,
          style: AppTextStyle.withColor(
            AppTextStyle.buttonMedium,
            Theme.of(context).textTheme.bodyLarge!.color!,
          ),
        ),
        subtitle:Text(
          subtitle,
          style: AppTextStyle.withColor(
            AppTextStyle.bodySmall,
            isDark? Colors.grey[400]! : Colors.grey[600]!,
          ),
        ),
        trailing: Switch.adaptive(
            value: initialValue,
            onChanged: (value){},
            activeThumbColor: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildNavigationTitle(
        BuildContext context,
        String title,
        String subtitle,
        IconData icon,
      ){

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration:  BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow:[
          BoxShadow(
            color: isDark ?  Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ]
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(
          title,
          style: AppTextStyle.withColor(
            AppTextStyle.bodyMedium,
            Theme.of(context).textTheme.bodyLarge!.color!,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyle.withColor(
            AppTextStyle.buttonSmall,
            isDark ? Colors.grey[400]! : Colors.grey[600]!,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
        ),
        onTap:(){}
      ),
    );
  }
}
