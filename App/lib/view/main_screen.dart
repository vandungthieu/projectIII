import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_project/controller/navigation_controller.dart';
import 'package:mobile_project/controller/theme_controller.dart';
import 'package:mobile_project/view/account_screen.dart';
import 'package:mobile_project/view/alert_screen.dart';
import 'package:mobile_project/view/device_screen.dart';
import 'package:mobile_project/view/home_sceen.dart';
import 'package:mobile_project/view/widgets/custom_bottom_navbar.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context){
    final NavigationController navigationController = Get.put(NavigationController());
    
    return GetBuilder<ThemeController>(
        builder: (themeController) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: AnimatedSwitcher(
            duration: Duration(milliseconds: 200),
            child: Obx(
                ()=> IndexedStack(
                  key : ValueKey(navigationController.currentIndex.value),
                  index: navigationController.currentIndex.value,
                  children: [
                    HomeScreen(),
                    DeviceScreen(),
                    AlertScreen(),
                    AccountScreen(),
                  ],
                )
            ),
          ),
          bottomNavigationBar: CustomBottomNavbar(),
        )
    );
  }
}