import 'package:get/get.dart';
import 'package:mobile_project/controller/alert_controller.dart';
import 'package:mobile_project/controller/device_controller.dart';
import 'package:mobile_project/controller/sensorData_controller.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:logger/logger.dart';

class SocketService {
  IO.Socket? socket;
  final logger = Logger();

  void connect(String token) {
    if (socket?.connected == true) return;
    socket?.dispose();

    socket = IO.io(
      'http://10.0.2.2:3000',
      IO.OptionBuilder()
          .setPath('/socket.io')
          .setTransports(['websocket'])
          .enableAutoConnect()
          .disableReconnection()
          .build(),
    );

    socket!.onConnect((_) {
      logger.i(" Socket connected");

      // Gửi token lên backend
      socket!.emit('auth', {"token": token});
      logger.i(" Sent auth token");
    });

    // Backend phản hồi sau khi authenticate
    socket!.on('receive', (data) {
      logger.i(" Server message: $data");
    });

    // Nhận cảnh báo mới
    socket!.on('alert', (alertJson) {
      logger.i(" NEW ALERT: $alertJson");

      if (Get.isRegistered<DeviceController>()) {
        Get.find<DeviceController>().updateStatusFromRealtime(alertJson);
      }

      if (Get.isRegistered<AlertController>()) {
        Get.find<AlertController>().addAlertFromSocket(alertJson);
      }
    });

    //  sensor data
    socket!.on('sensorData', (sensorDataJson) {
      logger.i("🔥 SOCKET sensorData RECEIVED");

      logger.i(
        "isRegistered SensorDataController: "
        "${Get.isRegistered<SensorDataController>()}",
      );

      if (Get.isRegistered<SensorDataController>()) {
        Get.find<SensorDataController>().updateFromSocket(sensorDataJson);
      }
    });

    socket!.onDisconnect((_) {
      logger.w(" Socket disconnected");
    });
  }

  void disconnect() {
    socket?.disconnect();
  }
}
