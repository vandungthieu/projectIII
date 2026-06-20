import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:mobile_project/controller/device_controller.dart';
import 'package:mobile_project/controller/sensorData_controller.dart';
import 'package:mobile_project/models/device.dart';
import 'package:mobile_project/models/journey.dart';
import 'package:mobile_project/models/sensorData.dart';
import 'package:mobile_project/utils/app_themes.dart';
import 'package:mobile_project/view/widgets/custom_textfield.dart';
import 'package:mobile_project/view/widgets/date_filter_bar.dart';
import 'package:latlong2/latlong.dart';
import 'package:timeago/timeago.dart' as timeago;

class DeviceDetailScreen extends StatefulWidget {
  final Device device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  static const int _sensorPageSize = 8;

  late final SensorDataController sensorCtrl;
  int _sensorPage = 0;

  @override
  void initState() {
    super.initState();
    sensorCtrl = Get.find<SensorDataController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sensorCtrl.setDevice(widget.device.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceCtrl = Get.find<DeviceController>();

    return Obx(() {
      final matches = deviceCtrl.devices.where(
        (device) => device.id == widget.device.id,
      );
      final device = matches.isEmpty ? widget.device : matches.first;

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Chi tiết thiết bị'),
          actions: [
            IconButton(
              tooltip: 'Chỉnh sửa biển số',
              onPressed: () => _showUpdate(context),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: sensorCtrl.refreshData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _DeviceHero(device: device),
              const SizedBox(height: 14),
              _ActionPanel(device: device),
              const SizedBox(height: 14),
              _LocationMapSection(device: device, sensorCtrl: sensorCtrl),
              const SizedBox(height: 18),
              const Text(
                'Dữ liệu cảm biến',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Obx(
                () => DateFilterBar(
                  selectedDate: sensorCtrl.selectedSensorDate.value,
                  onDateSelected: (date) {
                    setState(() => _sensorPage = 0);
                    sensorCtrl.setSensorDate(date);
                  },
                  onClear: () {
                    setState(() => _sensorPage = 0);
                    sensorCtrl.setSensorDate(null);
                  },
                ),
              ),
              const SizedBox(height: 10),
              Obx(() {
                if (sensorCtrl.isLoading.value) {
                  return const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final list = sensorCtrl.sensorList;
                if (list.isEmpty) {
                  return const _EmptySensorState();
                }

                final totalPages = ((list.length - 1) ~/ _sensorPageSize) + 1;
                final page = _sensorPage >= totalPages
                    ? totalPages - 1
                    : _sensorPage;
                final start = page * _sensorPageSize;
                final end = (start + _sensorPageSize) > list.length
                    ? list.length
                    : start + _sensorPageSize;
                final pageItems = list.sublist(start, end);

                return _SensorHistorySection(
                  items: pageItems,
                  currentPage: page,
                  totalPages: totalPages,
                  totalItems: list.length,
                  startIndex: start,
                  endIndex: end,
                  onPrevious: page == 0
                      ? null
                      : () => setState(() => _sensorPage = page - 1),
                  onNext: page >= totalPages - 1
                      ? null
                      : () => setState(() => _sensorPage = page + 1),
                );
              }),
            ],
          ),
        ),
      );
    });
  }

  void _showRemoveDialog(BuildContext context) {
    final deviceCtrl = Get.find<DeviceController>();

    Get.dialog(
      AlertDialog(
        title: const Text('Gỡ thiết bị?'),
        content: const Text(
          'Thiết bị sẽ được gỡ khỏi tài khoản của bạn. Bạn có thể kích hoạt lại bằng mã thiết bị và khóa thiết bị.',
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              deviceCtrl.deleteMyDevice(widget.device.id);
              Get.back();
              Get.back();
            },
            child: const Text('Gỡ thiết bị'),
          ),
        ],
      ),
    );
  }

  void _showUpdate(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final deviceCtrl = Get.find<DeviceController>();
    final licensePlateController = TextEditingController(
      text: widget.device.licensePlate ?? '',
    );

    Get.dialog(
      AlertDialog(
        title: const Text('Cập nhật biển số'),
        content: Form(
          key: formKey,
          child: CustomTextfield(
            label: 'Biển số xe',
            prefixIcon: Icons.confirmation_number_outlined,
            controller: licensePlateController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập biển số xe';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final success = await deviceCtrl.updateMyDevice(
                deviceId: widget.device.id,
                licensePlate: licensePlateController.text.trim(),
              );

              if (success) {
                Get.back();
                Get.back();
                Get.snackbar(
                  'Thành công',
                  'Đã cập nhật biển số xe',
                  snackPosition: SnackPosition.BOTTOM,
                );
              } else {
                Get.snackbar(
                  'Thất bại',
                  'Không thể cập nhật biển số',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}

class _DeviceHero extends StatelessWidget {
  final Device device;

  const _DeviceHero({required this.device});

  @override
  Widget build(BuildContext context) {
    final isMoving = device.vehicleStatus == VehicleStatus.moving;
    final isProtected = device.vehicleStatus == VehicleStatus.parked;
    final isStolen = device.vehicleStatus == VehicleStatus.stolen;
    final statusColor = isStolen
        ? AppColors.danger
        : isProtected
        ? AppColors.success
        : isMoving
        ? AppColors.warning
        : AppColors.muted;
    final title = device.licensePlate?.trim().isNotEmpty == true
        ? device.licensePlate!
        : device.deviceId;
    final activatedText = device.activatedAt == null
        ? 'Chưa kích hoạt'
        : DateFormat('dd/MM/yyyy').format(device.activatedAt!);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: statusColor,
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
                child: Icon(
                  isStolen
                      ? Icons.warning_amber_rounded
                      : isProtected
                      ? Icons.shield
                      : Icons.shield_outlined,
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
                      isStolen
                          ? 'Xe đang ở trạng thái nguy hiểm'
                          : isProtected
                          ? 'Xe đang được bảo vệ'
                          : isMoving
                          ? 'Xe đang không được bảo vệ'
                          : 'Chưa xác định chế độ bảo vệ',
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
          Row(
            children: [
              Expanded(
                child: _HeroMeta(label: 'Mã thiết bị', value: device.deviceId),
              ),
              Expanded(
                child: _HeroMeta(label: 'Kích hoạt', value: activatedText),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _HeroMeta(
            label: 'Cập nhật gần nhất',
            value: timeago.format(device.lastSeen, locale: 'vi'),
          ),
        ],
      ),
    );
  }
}

class _LocationMapSection extends StatelessWidget {
  final Device device;
  final SensorDataController sensorCtrl;

  const _LocationMapSection({required this.device, required this.sensorCtrl});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final journey = sensorCtrl.journey.value;
      final routePoints =
          journey?.points
              .map((point) => LatLng(point.lat, point.lng))
              .toList() ??
          const <LatLng>[];
      final fallbackPoint = _pointFromLocation(_currentLocation());
      final mapPoints = routePoints.isNotEmpty
          ? routePoints
          : fallbackPoint == null
          ? const <LatLng>[]
          : [fallbackPoint];

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
                const Icon(Icons.map_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Hành trình',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  _distanceText(journey?.distanceMeters ?? 0),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<JourneyPeriod>(
                segments: const [
                  ButtonSegment(
                    value: JourneyPeriod.day,
                    label: Text('24 giờ'),
                  ),
                  ButtonSegment(
                    value: JourneyPeriod.week,
                    label: Text('7 ngày'),
                  ),
                  ButtonSegment(
                    value: JourneyPeriod.all,
                    label: Text('Tất cả'),
                  ),
                ],
                selected: {sensorCtrl.journeyPeriod.value},
                showSelectedIcon: false,
                onSelectionChanged: sensorCtrl.isJourneyLoading.value
                    ? null
                    : (selected) => sensorCtrl.setJourneyPeriod(selected.first),
              ),
            ),
            if (sensorCtrl.isJourneyLoading.value) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(minHeight: 2),
            ],
            const SizedBox(height: 12),
            if (mapPoints.isEmpty)
              _EmptyMapState(device: device)
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 240,
                  child: Stack(
                    children: [
                      _OpenStreetMapView(
                        key: ValueKey(
                          '${sensorCtrl.journeyPeriod.value}-${mapPoints.length}',
                        ),
                        points: mapPoints,
                        onTap: () =>
                            _openFullScreenMap(context, mapPoints, journey),
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
                            onPressed: () =>
                                _openFullScreenMap(context, mapPoints, journey),
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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            child: Text(
                              routePoints.length > 1
                                  ? '${routePoints.length} điểm GPS'
                                  : 'Chạm để phóng to',
                              style: const TextStyle(
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
          ],
        ),
      );
    });
  }

  Map<String, dynamic>? _currentLocation() {
    if (sensorCtrl.sensorList.isNotEmpty &&
        sensorCtrl.sensorList.first.location != null) {
      return sensorCtrl.sensorList.first.location;
    }
    return device.latestLocation;
  }

  LatLng? _pointFromLocation(Map<String, dynamic>? location) {
    if (location == null) return null;

    final lat = _readCoordinate(location, ['lat', 'latitude']);
    final lng = _readCoordinate(location, ['lng', 'lon', 'long', 'longitude']);
    if (lat == null || lng == null) return null;

    return LatLng(lat, lng);
  }

  double? _readCoordinate(Map<String, dynamic> location, List<String> keys) {
    for (final key in keys) {
      final value = location[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
    }
    return null;
  }

  String _distanceText(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  void _openFullScreenMap(
    BuildContext context,
    List<LatLng> points,
    Journey? journey,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenMapPage(
          points: points,
          journey: journey,
          title: device.licensePlate?.trim().isNotEmpty == true
              ? device.licensePlate!
              : device.deviceId,
        ),
      ),
    );
  }
}

class _OpenStreetMapView extends StatelessWidget {
  final List<LatLng> points;
  final VoidCallback? onTap;

  const _OpenStreetMapView({super.key, required this.points, this.onTap});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: points.last,
        initialZoom: 16,
        initialCameraFit: points.length > 1
            ? CameraFit.coordinates(
                coordinates: points,
                padding: const EdgeInsets.all(36),
                maxZoom: 17,
              )
            : null,
        onTap: onTap == null ? null : (tapPosition, point) => onTap!(),
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
        if (points.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                strokeWidth: 5,
                color: AppColors.primary,
                borderStrokeWidth: 2,
                borderColor: Colors.white,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            Marker(
              point: points.first,
              width: 38,
              height: 38,
              child: const _RouteMarker(
                icon: Icons.trip_origin,
                color: AppColors.success,
                tooltip: 'Điểm bắt đầu',
              ),
            ),
            if (points.length > 1)
              Marker(
                point: points.last,
                width: 42,
                height: 42,
                child: const _RouteMarker(
                  icon: Icons.location_on,
                  color: AppColors.danger,
                  tooltip: 'Vị trí cuối',
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

class _RouteMarker extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;

  const _RouteMarker({
    required this.icon,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}

class _FullScreenMapPage extends StatelessWidget {
  final List<LatLng> points;
  final Journey? journey;
  final String title;

  const _FullScreenMapPage({
    required this.points,
    required this.journey,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Stack(
        children: [
          _OpenStreetMapView(points: points),
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
                  const Icon(Icons.route, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${journey?.points.length ?? points.length} điểm GPS',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (journey?.points.isNotEmpty == true)
                          Text(
                            '${DateFormat('dd/MM HH:mm').format(journey!.points.first.createdAt.toLocal())} - '
                            '${DateFormat('dd/MM HH:mm').format(journey!.points.last.createdAt.toLocal())}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    _distanceText(journey?.distanceMeters ?? 0),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
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

  String _distanceText(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }
}

class _EmptyMapState extends StatelessWidget {
  final Device device;

  const _EmptyMapState({required this.device});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.lightBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_off_outlined,
            size: 44,
            color: AppColors.muted,
          ),
          const SizedBox(height: 10),
          const Text(
            'Chưa có vị trí để hiển thị',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Thiết bị ${device.deviceId} sẽ hiện trên bản đồ khi có dữ liệu GPS.',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white60 : AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _HeroMeta extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMeta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  final Device device;

  const _ActionPanel({required this.device});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DeviceController>();
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
      child: Obx(() {
        final isProtected = device.vehicleStatus == VehicleStatus.parked;
        final isBuzzerOn = device.buzzerStatus;
        final isTogglingStatus = ctrl.togglingDeviceId.value == device.id;
        final isTogglingBuzzer = ctrl.togglingBuzzerId.value == device.id;

        return Row(
          children: [
            Expanded(
              child: _DetailAction(
                icon: isProtected ? Icons.shield_outlined : Icons.shield,
                label: isProtected ? 'Tắt bảo vệ' : 'Bật bảo vệ',
                color: isProtected ? AppColors.success : AppColors.warning,
                loading: isTogglingStatus,
                onTap: () => ctrl.toggleVehicleStatus(device.id, isProtected),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DetailAction(
                icon: isBuzzerOn ? Icons.volume_off : Icons.volume_up,
                label: isBuzzerOn ? 'Tắt còi' : 'Bật còi',
                color: isBuzzerOn ? AppColors.danger : AppColors.primary,
                loading: isTogglingBuzzer,
                onTap: () => ctrl.toggleBuzzer(device.id, !isBuzzerOn),
              ),
            ),
            const SizedBox(width: 10),
            _IconOnlyAction(
              tooltip: 'Gỡ thiết bị',
              icon: Icons.delete_outline,
              color: AppColors.danger,
              onTap: () => _showRemove(context),
            ),
          ],
        );
      }),
    );
  }

  void _showRemove(BuildContext context) {
    final state = context.findAncestorStateOfType<_DeviceDetailScreenState>();
    state?._showRemoveDialog(context);
  }
}

class _DetailAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _DetailAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: loading ? null : onTap,
      icon: loading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
    );
  }
}

class _IconOnlyAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconOnlyAction({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.35)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.all(13),
          minimumSize: const Size(48, 48),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

class _SensorHistorySection extends StatelessWidget {
  final List<SensorData> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int startIndex;
  final int endIndex;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _SensorHistorySection({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.startIndex,
    required this.endIndex,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${startIndex + 1}-$endIndex / $totalItems bản ghi',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Trang trước',
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${currentPage + 1}/$totalPages',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              IconButton(
                tooltip: 'Trang sau',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        ...items.map(
          (data) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SensorDataRow(data: data),
          ),
        ),
      ],
    );
  }
}

class _SensorDataRow extends StatelessWidget {
  final SensorData data;

  const _SensorDataRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final speed = data.speed ?? 0;
    final isOverSpeed = speed > 10;
    final color = isOverSpeed ? AppColors.danger : AppColors.success;
    final location = data.location == null
        ? 'Chưa có vị trí'
        : _locationText(data.location!);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.speed, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${speed.toStringAsFixed(1)} km/h',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('HH:mm').format(data.createdAt.toLocal()),
            style: TextStyle(
              color: isDark ? Colors.white54 : AppColors.muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _locationText(Map<String, dynamic> location) {
    final lat = location['lat'] ?? location['latitude'];
    final lng =
        location['lng'] ??
        location['lon'] ??
        location['long'] ??
        location['longitude'];

    if (lat == null || lng == null) return 'Chưa có vị trí';
    return '$lat, $lng';
  }
}

class _EmptySensorState extends StatelessWidget {
  const _EmptySensorState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.sensors_off_outlined,
            size: 44,
            color: isDark ? Colors.white54 : AppColors.muted,
          ),
          const SizedBox(height: 12),
          const Text(
            'Chưa có dữ liệu cảm biến',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Dữ liệu sẽ xuất hiện khi thiết bị gửi vị trí và tốc độ mới.',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white60 : AppColors.muted),
          ),
        ],
      ),
    );
  }
}
