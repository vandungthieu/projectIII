import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _securityChannelId = 'security_alerts';
  static const String _deviceChannelId = 'device_actions';

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: settings);
    await _createAndroidChannels();
    await _requestPermissions();

    _initialized = true;
  }

  Future<void> showSecurityAlert({
    required int id,
    required String title,
    required String body,
    bool critical = false,
    String? payload,
  }) async {
    await init();

    final androidDetails = AndroidNotificationDetails(
      _securityChannelId,
      'Security alerts',
      channelDescription: 'Vehicle anti-theft and stolen alerts',
      importance: Importance.max,
      priority: critical ? Priority.max : Priority.high,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ticker: title,
      styleInformation: BigTextStyleInformation(body),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      ),
      payload: payload,
    );
  }

  Future<void> showDeviceAction({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();

    final androidDetails = AndroidNotificationDetails(
      _deviceChannelId,
      'Device actions',
      channelDescription: 'Device control status notifications',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
      ticker: title,
      styleInformation: BigTextStyleInformation(body),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );

    await _plugin.show(
      id: 100000 + id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      ),
      payload: payload,
    );
  }

  Future<void> _createAndroidChannels() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return;

    const securityChannel = AndroidNotificationChannel(
      _securityChannelId,
      'Security alerts',
      description: 'Vehicle anti-theft and stolen alerts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const deviceChannel = AndroidNotificationChannel(
      _deviceChannelId,
      'Device actions',
      description: 'Device control status notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await androidPlugin.createNotificationChannel(securityChannel);
    await androidPlugin.createNotificationChannel(deviceChannel);
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    final macPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    await macPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }
}
