import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:mobile_project/models/journey.dart';
import 'package:mobile_project/models/sensorData.dart';

final logger = Logger();

class SensorDataService {
  final String baseUrl = "http://10.0.2.2:3000";

  Future<List<SensorData>?> getSensorDataByDevice(
    String token,
    int deviceId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final query = <String, String>{
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
    };
    final url = Uri.parse(
      '$baseUrl/devices/sensor/$deviceId',
    ).replace(queryParameters: query.isEmpty ? null : query);

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

          // Lọc bỏ phần tử null để tránh lỗi
          final cleaned = data.where((e) => e != null).toList();

          return cleaned.map((json) => SensorData.fromJson(json)).toList();
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

  Future<Journey?> getJourneyByDevice(
    String token,
    int deviceId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final query = <String, String>{
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
    };
    final url = Uri.parse(
      '$baseUrl/devices/journey/$deviceId',
    ).replace(queryParameters: query.isEmpty ? null : query);

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        logger.w('Journey API error: ${response.body}');
        return null;
      }

      return Journey.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (e) {
      logger.e('Journey request failed: $e');
      return null;
    }
  }
}
