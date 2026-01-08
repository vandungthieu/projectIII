// lib/services/device_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/device.dart';

final logger = Logger();

class DeviceService {
  final String baseUrl = "http://10.0.2.2:3000";

  Future<List<Device>?> getMyDevices(String token) async {
    final url = Uri.parse("$baseUrl/devices/my-device");

    try {
      logger.i("➡️ GET $url");
      logger.i("➡️ Authorization: Bearer $token");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      logger.i("⬅️ Status Code: ${response.statusCode}");
      logger.i("⬅️ Raw Body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = jsonDecode(response.body);

          logger.i("📦 Tổng số thiết bị nhận được: ${data.length}");

          // log từng item
          for (var item in data) {
            logger.i("📌 Device JSON: $item");
          }

          return data.map((json) => Device.fromJson(json)).toList();
        } catch (e) {
          logger.e("❌ Lỗi parse JSON: $e");
          return null;
        }
      } else {
        logger.w("⚠️ Lỗi API: ${response.body}");
        return null;
      }
    } catch (e) {
      logger.e("❌ Exception khi gọi API: $e");
      return null;
    }
  }

  // câp nhật trạng thai xe
  Future<bool> updateVehicleStatus({
    required int id,
    required String status,
    required String token,
  }) async {
    final url = Uri.parse("$baseUrl/devices/my-device/$id");

    try {
      final response = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"vehicleStatus": status}),
      );


      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // dieu khien coi
  Future<bool> updateBuzzerStatus({
    required String deviceId,
    required bool turnOn,  // true = bật, false = tắt
    required String token,
  }) async {
    final url = Uri.parse("$baseUrl/buzzer"); // endpoint của bạn

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "deviceId": deviceId,
          "action": turnOn ? "on" : "off",
        }),
      );


      return response.statusCode == 201;

    } catch (e) {
      return false;
    }
  }

  // kich hoat thiet bi
  Future<Map<String, dynamic>> activateDevice({
    required String deviceId,
    required String deviceKey,
    required String token,
  }) async {
    final url = Uri.parse("$baseUrl/devices/active");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "deviceId": deviceId,
        "deviceKey": deviceKey,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error: ${response.statusCode} - ${response.body}");
    }
  }

  // Xóa thiết bị
  Future<bool> deleteMyDevice({
    required int deviceId,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/devices/my-device/$deviceId');

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Delete device failed');
    }
  }

  // chỉnh sửa
  Future<bool> updateMyDevice(
      int deviceId,
      String licensePlate,
      String token,
      ) async {
    final url = Uri.parse('$baseUrl/devices/my-device/$deviceId');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'licensePlate': licensePlate,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Update device failed');
    }
  }




}
