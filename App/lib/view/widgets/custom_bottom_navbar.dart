import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_project/controller/navigation_controller.dart';

class CustomBottomNavbar extends StatelessWidget {
  const CustomBottomNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationController navigationController =Get.find<NavigationController>();

    return Obx(
        ()=> BottomNavigationBar(
          currentIndex: navigationController.currentIndex.value,
          onTap: (value) => navigationController.changeIndex(value),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label :'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.device_hub),
              label :'Device',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              label :'Alert',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label :'Account',
            ),
          ],
        )
    );
  }
}
