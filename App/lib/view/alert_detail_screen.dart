import 'package:flutter/material.dart';
import 'package:mobile_project/models/alert.dart';
import 'package:intl/intl.dart';
import 'package:mobile_project/utils/app_textstyles.dart';

class AlertDetailScreen extends StatelessWidget {
  final Alert alert;

  const AlertDetailScreen({
    super.key,
    required this.alert,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryColor = isDark ? Colors.white60 : Colors.black54;
    final speed = alert.speed != null ? "${alert.speed!.toStringAsFixed(1)} km/h" : "Không có";

    // Định dạng thời gian
    final formattedTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(alert.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chi Tiết Cảnh Báo',
          style: AppTextStyle.withColor(
            AppTextStyle.h2,
            isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: isDark ? Colors.grey[850] : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message
                Text(
                  "Thông báo",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  alert.message,
                  style: TextStyle(fontSize: 16, color: textColor),
                ),

                const Divider(height: 24),

                // Device ID & License Plate
                Text(
                  "Thiết bị",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Device ID: ${alert.deviceCode}",
                  style: TextStyle(fontSize: 16, color: secondaryColor),
                ),
                Text(
                  "Biển số: ${alert.licensePlate ?? 'Chưa có'}",
                  style: TextStyle(fontSize: 16, color: secondaryColor),
                ),
                const Divider(height: 24),

                // Tốc độ
                Text(
                  "Tốc độ",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  speed,
                  style: TextStyle(fontSize: 16, color: secondaryColor),
                ),
                const Divider(height: 24),

                // Location
                Text(
                  "Vị trí",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  alert.hasLocation
                      ? "Lat: ${alert.lat}, Lng: ${alert.lng}"
                      : "Không có thông tin vị trí",
                  style: TextStyle(fontSize: 16, color: secondaryColor),
                ),
                const Divider(height: 24),

                // Thời gian
                Text(
                  "Thời gian",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formattedTime,
                  style: TextStyle(fontSize: 16, color: secondaryColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
