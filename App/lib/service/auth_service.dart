import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:mobile_project/models/user.dart';

final logger = Logger();

class AuthService {
  final String baseUrl = "http://10.0.2.2:3000";

  // --- Login ---
  Future<Map<String, dynamic>?> login(String username, String password) async {
    final url = Uri.parse("$baseUrl/auth/login");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      logger.i("Status code: ${response.statusCode}");
      logger.i("Response body: ${response.body}");

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        logger.w("Login failed: ${response.body}");
        return null;
      }
    } catch (e) {
      logger.e("Error during login: $e");
      return null;
    }
  }

  // ---- Register----
  Future<Map<String, dynamic>?> register(
    String username,
    String password,
    String email,
  ) async {
    final url = Uri.parse("$baseUrl/auth/register");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
          "email": email,
        }),
      );

      logger.i("Register status: ${response.statusCode}");
      logger.i("Register body: ${response.body}");

      if (response.statusCode == 201) {
        // backend trả 201 khi tạo thành công
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      logger.e("Register error: $e");
      return null;
    }
  }

  // ---Get Profile---
  Future<User?> getUserInfo(String token) async {
    final url = Uri.parse("$baseUrl/user/profile");

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
          final Map<String, dynamic> data = jsonDecode(response.body);

          // Trả về duy nhất 1 user
          return User.fromJson(data);
        } catch (e) {
          logger.e(" Lỗi parse JSON: $e");
          return null;
        }
      } else {
        logger.w(" Lỗi API: ${response.body}");
        return null;
      }
    } catch (e) {
      logger.e(" Exception khi gọi API: $e");
      return null;
    }
  }

  // --- Update Profile----
  Future<Map<String, dynamic>?> updateProfile(
    String? name,
    String? email,
    String? phone,
    String token,
  ) async {
    final url = Uri.parse("$baseUrl/user/profile");
    try {
      // Build body động
      final Map<String, dynamic> data = {};

      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;

      final response = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // change password
  Future<Map<String, dynamic>?> changePassword(
    String oldPassword,
    String newPassword,
    String token,
  ) async {
    final url = Uri.parse("$baseUrl/user/change-password");

    try {
      final response = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "oldPassword": oldPassword,
          "newPassword": newPassword,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }

      // debug lỗi backend
      print("Change password failed: ${response.body}");
      return null;
    } catch (e) {
      print("Change password error: $e");
      return null;
    }
  }

  Future<bool> saveFcmToken({
    required String token,
    required String authToken,
    String? platform,
    String? deviceName,
  }) async {
    final url = Uri.parse("$baseUrl/user/fcm-token");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $authToken",
        },
        body: jsonEncode({
          "token": token,
          if (platform != null) "platform": platform,
          if (deviceName != null) "deviceName": deviceName,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      logger.e("Save FCM token error: $e");
      return false;
    }
  }

  Future<bool> deleteFcmToken({
    required String token,
    required String authToken,
  }) async {
    final url = Uri.parse("$baseUrl/user/fcm-token");

    try {
      final request = http.Request("DELETE", url)
        ..headers.addAll({
          "Content-Type": "application/json",
          "Authorization": "Bearer $authToken",
        })
        ..body = jsonEncode({"token": token});

      final response = await request.send();
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      logger.e("Delete FCM token error: $e");
      return false;
    }
  }
}
