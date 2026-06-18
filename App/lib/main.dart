import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobile_project/controller/alert_controller.dart';
import 'package:mobile_project/controller/auth_controller.dart';
import 'package:mobile_project/controller/device_controller.dart';
import 'package:mobile_project/controller/navigation_controller.dart';
import 'package:mobile_project/controller/sensorData_controller.dart';
import 'package:mobile_project/controller/theme_controller.dart';
import 'package:mobile_project/service/fcm_service.dart';
import 'package:mobile_project/service/notification_service.dart';
import 'package:mobile_project/service/socket_service.dart';
import 'package:mobile_project/utils/app_themes.dart';
import 'package:mobile_project/view/splash_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await NotificationService.instance.init();
  await FcmService.instance.init();

  Get.put<NotificationService>(NotificationService.instance, permanent: true);
  Get.put<FcmService>(FcmService.instance, permanent: true);
  Get.put(SocketService(), permanent: true);
  Get.put(ThemeController());
  Get.put(AuthController());
  Get.put(NavigationController());
  Get.put(DeviceController(), permanent: true);
  Get.put(AlertController());
  Get.put(SensorDataController(), permanent: true);

  timeago.setLocaleMessages('vi', timeago.ViMessages());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return GetMaterialApp(
      title: 'App Chống Trộm Xe',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.light,
      darkTheme: AppThemes.dark,
      themeMode: themeController.theme,
      defaultTransition: Transition.fade,
      home: SplashScreen(),
    );
  }
}
