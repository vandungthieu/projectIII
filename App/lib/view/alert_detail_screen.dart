import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_project/models/alert.dart';
import 'package:mobile_project/utils/app_themes.dart';
import 'package:timeago/timeago.dart' as timeago;

class AlertDetailScreen extends StatelessWidget {
  final Alert alert;

  const AlertDetailScreen({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final speed = alert.speed == null
        ? 'Không có'
        : '${alert.speed!.toStringAsFixed(1)} km/h';
    final title = alert.licensePlate?.trim().isNotEmpty == true
        ? alert.licensePlate!
        : alert.deviceCode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Chi tiết cảnh báo')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeago.format(alert.createdAt, locale: 'vi'),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.84),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  alert.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _InfoCard(
            children: [
              _InfoRow(
                icon: Icons.memory,
                label: 'Mã thiết bị',
                value: alert.deviceCode,
              ),
              _InfoRow(
                icon: Icons.confirmation_number_outlined,
                label: 'Biển số',
                value: alert.licensePlate ?? 'Chưa có',
              ),
              _InfoRow(
                icon: Icons.speed,
                label: 'Tốc độ',
                value: speed,
                valueColor: alert.speed == null ? null : AppColors.danger,
              ),
              _InfoRow(
                icon: Icons.schedule,
                label: 'Thời gian',
                value: DateFormat(
                  'dd/MM/yyyy HH:mm:ss',
                ).format(alert.createdAt),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _LocationSection(alert: alert),
        ],
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  final Alert alert;

  const _LocationSection({required this.alert});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Vị trí',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!alert.hasLocation)
            SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'Không có thông tin vị trí',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : AppColors.muted,
                  ),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () {
                Get.to(
                  () => _FullScreenAlertMapPage(
                    point: LatLng(alert.lat!, alert.lng!),
                    title: alert.licensePlate?.trim().isNotEmpty == true
                        ? alert.licensePlate!
                        : alert.deviceCode,
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 240,
                      child: Stack(
                        children: [
                          _OpenStreetMapView(
                            point: LatLng(alert.lat!, alert.lng!),
                            zoom: 16,
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Material(
                              color: Theme.of(
                                context,
                              ).cardColor.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(8),
                              child: IconButton(
                                tooltip: 'Phóng to bản đồ',
                                onPressed: () {
                                  Get.to(
                                    () => _FullScreenAlertMapPage(
                                      point: LatLng(alert.lat!, alert.lng!),
                                      title:
                                          alert.licensePlate
                                                  ?.trim()
                                                  .isNotEmpty ==
                                              true
                                          ? alert.licensePlate!
                                          : alert.deviceCode,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.open_in_full),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            bottom: 10,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.56),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                child: Text(
                                  'Chạm để phóng to',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${alert.lat!.toStringAsFixed(6)}, ${alert.lng!.toStringAsFixed(6)}',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OpenStreetMapView extends StatelessWidget {
  final LatLng point;
  final double zoom;

  const _OpenStreetMapView({required this.point, required this.zoom});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: point,
        initialZoom: zoom,
        interactionOptions: const InteractionOptions(
          flags:
              InteractiveFlag.drag |
              InteractiveFlag.pinchZoom |
              InteractiveFlag.doubleTapZoom,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'mobile_project',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: point,
              width: 52,
              height: 52,
              child: const Icon(
                Icons.location_pin,
                size: 52,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }
}

class _FullScreenAlertMapPage extends StatelessWidget {
  final LatLng point;
  final String title;

  const _FullScreenAlertMapPage({required this.point, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Stack(
        children: [
          _OpenStreetMapView(point: point, zoom: 17),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : AppColors.muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
