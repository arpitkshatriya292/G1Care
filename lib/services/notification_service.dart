import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/routing/app_router.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int emergencyNotificationId = 91101;
  static const String emergencyChannelId = 'g1care_live_navigation_channel';
  static const String emergencyChannelName = 'G1Care Live Emergency Navigation';
  static const String emergencyChannelDescription =
      'Persistent live navigation and active emergency alerts for patient and response units';

  bool _isInitialized = false;
  String? _pendingPayload;

  String? get pendingPayload => _pendingPayload;

  void clearPendingPayload() {
    _pendingPayload = null;
  }

  /// Initialize local notification system and handle launch/tap routing
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request notification permission on Android 13+ (API 33+)
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.requestNotificationsPermission();
      }

      // Check if app was launched via notification tap
      final details =
          await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (details != null && details.didNotificationLaunchApp) {
        _pendingPayload = details.notificationResponse?.payload;
        debugPrint('App launched with notification payload: $_pendingPayload');
      }

      _isInitialized = true;
      debugPrint('G1Care NotificationService initialized successfully.');
    } catch (e) {
      debugPrint('NotificationService initialization notice ($e). Continuing with safe fallback.');
    }
  }

  /// Handle notification tap when app is in foreground or background
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('Notification tapped with payload: $payload');
    if (payload != null && payload.isNotEmpty) {
      _pendingPayload = payload;
      _routeToPayload(payload);
    }
  }

  /// Route user to the destination screen using global navigator key
  void _routeToPayload(String routeName) {
    try {
      final nav = AppRouter.navigatorKey.currentState;
      if (nav != null) {
        nav.pushNamed(routeName);
        _pendingPayload = null;
      }
    } catch (e) {
      debugPrint('Error navigating from notification: $e');
    }
  }

  /// Check and consume pending notification payload on home screen load
  void consumePendingNavigation() {
    if (_pendingPayload != null && _pendingPayload!.isNotEmpty) {
      final route = _pendingPayload!;
      _pendingPayload = null;
      Future.delayed(const Duration(milliseconds: 300), () {
        _routeToPayload(route);
      });
    }
  }

  /// Display or update ongoing Android Live Navigation notification
  Future<void> showActiveEmergencyNotification({
    required String incidentId,
    String title = 'G1Care — SOS ACTIVE',
    String body = 'Emergency assistance is active. Tap to view Live Navigation.',
    String payload = '/patient/emergency-map',
  }) async {
    try {
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        emergencyChannelId,
        emergencyChannelName,
        channelDescription: emergencyChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ongoing: true, // Remains ongoing while emergency is active
        autoCancel: false,
        showWhen: true,
        enableVibration: true,
        color: const Color(0xFF00A896),
        category: AndroidNotificationCategory.status,
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'G1Care Emergency Response',
        ),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id: emergencyNotificationId,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Notification display notice: $e');
    }
  }

  /// Cancel active emergency notification upon hospital resolution or patient cancel
  Future<void> cancelActiveEmergencyNotification() async {
    try {
      await _notificationsPlugin.cancel(id: emergencyNotificationId);
    } catch (e) {
      debugPrint('Notification cancellation notice: $e');
    }
  }
}
