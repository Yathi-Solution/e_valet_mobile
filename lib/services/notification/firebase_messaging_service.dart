import 'dart:async';
import 'package:niloufer_valet_mobile/models/notification/notification_type.dart';
import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:niloufer_valet_mobile/api/notification/notification_api_service.dart';
import 'package:niloufer_valet_mobile/models/notification/fcm_register_request.dart';
import 'package:niloufer_valet_mobile/services/device/device_info_service.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';
import 'notification_service.dart';
import 'local_notification_service.dart';
import 'text_to_speech_service.dart';
import 'package:niloufer_valet_mobile/services/vibration_controller.dart';

/// Top-level function to handle background messages.
/// Must be a top-level function (not a class method).
///
/// **Why TTS does not run here:** This handler runs in a separate Dart isolate
/// when the app is in background or terminated. That isolate has no Flutter
/// engine and no access to plugins (e.g. flutter_tts). TTS only works when the
/// app is in the foreground or when the user opens the app from a notification.
/// On Android, background/terminated TTS is handled by native code in
/// [ValetFirebaseMessagingService] (Kotlin).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('Background message received: ${message.messageId}');
  log('Title: ${message.notification?.title}');
  log('Body: ${message.notification?.body}');
  log('Data: ${message.data}');
}

class FirebaseMessagingService implements NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final LocalNotificationService _localNotificationService =
      LocalNotificationService();
  final NotificationApiService _notificationApiService =
      NotificationApiService();
  final TextToSpeechService _textToSpeechService = TextToSpeechService();

  final StreamController<Map<String, dynamic>> _messageStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Emits when user opens the app by tapping a retrieval_request notification.
  /// Driver home should refresh pending/session API and navigate to the right screen.
  final StreamController<void> _retrievalNotificationTapController =
      StreamController<void>.broadcast();
  Stream<void> get onRetrievalNotificationTap =>
      _retrievalNotificationTapController.stream;

  // Navigation key for global navigation
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Future<void> initialize() async {
    try {
      log('Initializing Firebase Messaging Service...');

      // Initialize local notifications
      await _localNotificationService.initialize();

      // Initialize TTS for speaking notification body aloud (loud, hearable)
      await _textToSpeechService.initialize();

      // Notification permission is requested on PermissionsScreen (before main app).

      // Get FCM token (but don't register yet - wait for login)
      final token = await getToken();
      if (token != null) {
        log('FCM Token: $token');
      }

      // Setup message handlers
      _setupMessageHandlers();

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Handle token refresh - only register if user is logged in
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        log('FCM Token refreshed: $newToken');
        // Check if user has access token before registering
        final accessToken = await TokenStorage.getAccessToken();
        if (accessToken != null && accessToken.isNotEmpty) {
          _registerFcmToken(newToken);
        }
        _messageStreamController.add({
          'type': 'token_refresh',
          'token': newToken,
        });
      });

      log('Firebase Messaging Service initialized successfully');
    } catch (e) {
      log('Error initializing Firebase Messaging Service: $e');
      rethrow;
    }
  }

  /// Register FCM token after successful login
  /// Call this method after user authentication is complete
  Future<void> registerFcmTokenAfterLogin() async {
    try {
      final token = await getToken();
      if (token != null) {
        await _registerFcmToken(token);
      } else {
        log('No FCM token available to register');
      }
    } catch (e) {
      log('Error registering FCM token after login: $e');
    }
  }

  @override
  Future<void> requestPermission() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      log('Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        log('User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        log('User granted provisional notification permission');
      } else {
        log('User declined or has not accepted notification permission');
      }
    } catch (e) {
      log('Error requesting notification permission: $e');
      rethrow;
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      log('FCM Token retrieved: $token');
      return token;
    } catch (e) {
      log('Error getting FCM token: $e');
      return null;
    }
  }

  @override
  Stream<Map<String, dynamic>> get onMessageReceived =>
      _messageStreamController.stream;

  @override
  Future<void> handleBackgroundMessage(Map<String, dynamic> message) async {
    try {
      log('Handling background message: $message');

      // Process the message based on type
      final notificationType = message['type'] as String?;

      // Add to stream for BLoC to handle
      _messageStreamController.add(message);

      // Navigate if needed based on notification type
      _handleNavigation(notificationType, message);
    } catch (e) {
      log('Error handling background message: $e');
    }
  }

  /// Setup handlers for different app states
  void _setupMessageHandlers() {
    // Foreground messages (app is open and active)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Foreground message received: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // Background messages (app is in background but not terminated)
    // User taps on notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('Notification opened app from background: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Terminated state (app was completely closed)
    // Check if app was opened from a notification
    _checkInitialMessage();
  }

  /// Handle messages when app is in foreground
  void _handleForegroundMessage(RemoteMessage message) {
    try {
      log('Processing foreground message...');

      final notification = message.notification;
      final data = message.data;

      // Show local notification when app is in foreground
      if (notification != null) {
        // Include body in payload so TTS can speak it when user taps notification
        final payloadWithBody = Map<String, dynamic>.from(message.data)
          ..['body'] = notification.body
          ..['title'] = notification.title;
        _localNotificationService.showNotification(
          id: message.hashCode,
          title: notification.title ?? 'New Notification',
          body: notification.body ?? '',
          payload: payloadWithBody,
          importance: Importance.high,
          priority: Priority.high,
        );
        // Speak notification body aloud (loud, hearable TTS)
        final bodyText =
            notification.body ?? notification.title ?? 'New notification';
        _textToSpeechService.speak(bodyText);
      }

      // Add to stream for BLoC to handle
      _messageStreamController.add({
        'messageId': message.messageId,
        'title': notification?.title,
        'body': notification?.body,
        'data': data,
        'type': data['type'],
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Retrieval request arrived while app is in foreground — start vibration
      // immediately and trigger the same session-refresh that background taps use.
      if (isRetrievalAlertType(data['type'] as String?)) {
        VibrationController.startRetrievalAlert();
        _retrievalNotificationTapController.add(null);
      }
    } catch (e) {
      log('Error handling foreground message: $e');
    }
  }

  /// Handle when user taps on notification
  void _handleNotificationTap(RemoteMessage message) {
    try {
      log('Processing notification tap...');

      final data = message.data;
      final notificationType = data['type'] as String?;

      // Add to stream
      _messageStreamController.add({
        'messageId': message.messageId,
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': data,
        'type': notificationType,
        'action': 'tap',
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Speak notification body aloud when user opens from notification (loud, hearable)
      final bodyText =
          message.notification?.body ?? message.notification?.title;
      if (bodyText != null && bodyText.isNotEmpty) {
        _textToSpeechService.speak(bodyText);
      }

      // Navigate to appropriate screen
      _handleNavigation(notificationType, data);
    } catch (e) {
      log('Error handling notification tap: $e');
    }
  }

  /// Check if app was opened from a terminated state by tapping notification
  Future<void> _checkInitialMessage() async {
    try {
      final RemoteMessage? message =
          await _firebaseMessaging.getInitialMessage();

      if (message != null) {
        log('App opened from terminated state via notification: ${message.messageId}');

        // Delay to ensure app is fully initialized
        await Future.delayed(const Duration(seconds: 2));

        _handleNotificationTap(message);
      }
    } catch (e) {
      log('Error checking initial message: $e');
    }
  }

  /// Navigate to appropriate screen based on notification type
  void _handleNavigation(String? type, Map<String, dynamic> data) {
    if (type == null) return;

    try {
      // Always emit retrieval-tap event and start vibration, even if navigator
      // is not yet ready.
      if (isRetrievalAlertType(type)) {
        VibrationController.startRetrievalAlert();
        _retrievalNotificationTapController.add(null);
      }
      // Ensure navigator is ready before attempting navigation to avoid crashes.
      if (navigatorKey.currentContext == null) {
        log('Navigator not ready; skipping navigation for type: $type');
        return;
      }
      log('Navigating based on notification type: $type');
      switch (type) {
        case 'retrieval_request':
        case 'retrieval_assigned':
          _navigateToRetrievalRequest(data);
          break;
        case 'driver_assigned':
          _navigateToDriverDetails(data);
          break;
        case 'vehicle_ready':
          _navigateToVehicleStatus(data);
          break;
        case 'vehicle_delivered':
          _navigateToDeliveryConfirmation(data);
          break;
        case 'system_alert':
          _navigateToNotifications(data);
          break;
        default:
          log('Unknown notification type: $type');
          _navigateToNotifications(data);
      }
    } catch (e) {
      log('Error during navigation: $e');
    }
  }

  /// Navigation methods for different notification types
  void _navigateToRetrievalRequest(Map<String, dynamic> data) {
    final requestId = data['request_id'] as String?;
    if (requestId == null) return;

    log('Navigating to retrieval request: $requestId');
    // TODO: Implement navigation to retrieval request screen
    // navigatorKey.currentState?.pushNamed('/retrieval-request', arguments: requestId);
  }

  void _navigateToDriverDetails(Map<String, dynamic> data) {
    final driverId = data['driver_id'] as String?;
    if (driverId == null) return;

    log('Navigating to driver details: $driverId');
    // TODO: Implement navigation to driver details screen
    // navigatorKey.currentState?.pushNamed('/driver-details', arguments: driverId);
  }

  void _navigateToVehicleStatus(Map<String, dynamic> data) {
    final vehicleId = data['vehicle_id'] as String?;
    if (vehicleId == null) return;

    log('Navigating to vehicle status: $vehicleId');
    // TODO: Implement navigation to vehicle status screen
    // navigatorKey.currentState?.pushNamed('/vehicle-status', arguments: vehicleId);
  }

  void _navigateToDeliveryConfirmation(Map<String, dynamic> data) {
    final deliveryId = data['delivery_id'] as String?;
    if (deliveryId == null) return;

    log('Navigating to delivery confirmation: $deliveryId');
    // TODO: Implement navigation to delivery confirmation screen
    // navigatorKey.currentState?.pushNamed('/delivery-confirmation', arguments: deliveryId);
  }

  void _navigateToNotifications(Map<String, dynamic> data) {
    log('Navigating to notifications screen');
    // TODO: Implement navigation to notifications list screen
    // navigatorKey.currentState?.pushNamed('/notifications');
  }

  /// Subscribe to specific topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      log('Subscribed to topic: $topic');
    } catch (e) {
      log('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from specific topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      log('Unsubscribed from topic: $topic');
    } catch (e) {
      log('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Delete FCM token (useful for logout)
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      log('FCM token deleted');
    } catch (e) {
      log('Error deleting FCM token: $e');
    }
  }

  /// Register FCM token with backend
  Future<void> _registerFcmToken(String fcmToken) async {
    try {
      log('Registering FCM token with backend...');

      // Get device information
      final deviceInfo = await DeviceInfoService.getAllDeviceInfo();

      // Create registration request
      final request = FcmRegisterRequest(
        deviceId: deviceInfo['deviceId']!,
        fcmToken: fcmToken,
        platform: deviceInfo['platform']!,
        appVersion: deviceInfo['appVersion']!,
        osVersion: deviceInfo['osVersion']!,
      );

      // Register with backend
      final response = await _notificationApiService.registerFcmToken(request);

      if (response.success) {
        log('FCM token registered successfully with backend');
        log('Device ID: ${deviceInfo['deviceId']}');
        log('Platform: ${deviceInfo['platform']}');
        log('App Version: ${deviceInfo['appVersion']}');
        log('OS Version: ${deviceInfo['osVersion']}');
      } else {
        log('FCM token registration failed: ${response.message}');
      }
    } catch (e) {
      log('Error registering FCM token with backend: $e');
      // Don't rethrow - this is a background operation that shouldn't crash the app
    }
  }

  /// Dispose resources
  void dispose() {
    _retrievalNotificationTapController.close();
    _messageStreamController.close();
  }
}
