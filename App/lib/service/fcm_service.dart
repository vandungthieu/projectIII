import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:mobile_project/controller/alert_controller.dart';
import 'package:mobile_project/controller/device_controller.dart';
import 'package:mobile_project/controller/navigation_controller.dart';
import 'package:mobile_project/firebase_options.dart';
import 'package:mobile_project/service/auth_service.dart';

class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  final AuthService _authService = AuthService();
  final Logger _logger = Logger();

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  RemoteMessage? _pendingOpenedMessage;
  bool _initialized = false;
  bool _available = false;
  String? _authToken;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _available = true;

      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      await _messaging.setAutoInitEnabled(true);

      FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
      _foregroundMessageSubscription ??= FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleOpenedMessage(initialMessage);
      }
    } catch (e) {
      _available = false;
      _logger.w('FCM is not configured yet: $e');
    }
  }

  Future<void> registerToken(String authToken) async {
    _authToken = authToken;
    await init();
    if (!_available || authToken.isEmpty) return;

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(authToken, token);
    }

    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((token) {
      final currentAuthToken = _authToken;
      if (currentAuthToken == null || currentAuthToken.isEmpty) return;
      _saveToken(currentAuthToken, token);
    });
  }

  Future<void> unregisterToken(String authToken) async {
    await init();
    if (!_available || authToken.isEmpty) return;

    final token = await _messaging.getToken();
    if (token != null) {
      await _authService.deleteFcmToken(token: token, authToken: authToken);
    }
    _authToken = null;
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _foregroundMessageSubscription = null;
  }

  void processPendingMessage() {
    final message = _pendingOpenedMessage;
    if (message == null) return;

    _pendingOpenedMessage = null;
    _handleOpenedMessage(message);
  }

  Future<void> _saveToken(String authToken, String token) {
    return _authService.saveFcmToken(
      token: token,
      platform: _platform,
      deviceName: _platform,
      authToken: authToken,
    );
  }

  Future<void> _handleOpenedMessage(RemoteMessage message) async {
    if (message.data['type'] != 'alert') return;
    if (!Get.isRegistered<NavigationController>()) {
      _pendingOpenedMessage = message;
      return;
    }

    _syncDeviceStatus(message.data);

    final refreshTasks = <Future<void>>[];
    if (Get.isRegistered<DeviceController>()) {
      refreshTasks.add(Get.find<DeviceController>().refreshDevices());
    }
    if (Get.isRegistered<AlertController>()) {
      refreshTasks.add(Get.find<AlertController>().refreshAlert());
    }
    await Future.wait(refreshTasks);

    Get.find<NavigationController>().changeIndex(2);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.data['type'] != 'alert') return;
    _syncDeviceStatus(message.data);
  }

  void _syncDeviceStatus(Map<String, dynamic> data) {
    if (!Get.isRegistered<DeviceController>()) return;
    Get.find<DeviceController>().updateStatusFromRealtime(data);
  }

  String get _platform {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
}
