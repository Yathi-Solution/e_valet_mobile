import 'dart:convert';
import 'package:niloufer_valet_mobile/models/notification/notification_type.dart';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'text_to_speech_service.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize local notifications
  Future<void> initialize() async {
    if (_isInitialized) {
      log('Local notifications already initialized');
      return;
    }

    try {
      log('Initializing local notifications...');

      // Android initialization settings
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined initialization settings
      const initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize plugin with callback
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels for Android
      await _createNotificationChannels();

      _isInitialized = true;
      log('Local notifications initialized successfully');
    } catch (e) {
      log('Error initializing local notifications: $e');
      rethrow;
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      // Vibration pattern used for retrieval-request alerts:
      // immediate 900 ms buzz → 300 ms off → 900 ms → 300 ms → 900 ms → 300 ms → 900 ms
      // NOTE: Android channel properties are immutable after first creation.
      // If the app was previously installed, uninstall / clear app data to
      // let the new pattern take effect.
      final retrievalVibrationPattern =
          Int64List.fromList([0, 900, 300, 900, 300, 900, 300, 900]);

      // Custom sound for retrieval-request alerts (file in android/app/src/main/res/raw/).
      // NOTE: Android channel sound is immutable after first creation; uninstall
      // the app (or clear app data) to pick up a sound change.
      const retrievalSound =
          RawResourceAndroidNotificationSound('retrieval_alert');

      // High priority channel — this is the DEFAULT channel used by FCM for
      // background/terminated notifications (set in AndroidManifest.xml).
      // Uses the custom retrieval-alert sound + aggressive vibration pattern.
      final highPriorityChannel = AndroidNotificationChannel(
        'high_priority_channel',
        'High Priority Notifications',
        description: 'This channel is used for high priority notifications',
        importance: Importance.max,
        playSound: true,
        sound: retrievalSound,
        enableVibration: true,
        vibrationPattern: retrievalVibrationPattern,
      );

      // Default channel
      const defaultChannel = AndroidNotificationChannel(
        'default_channel',
        'Default Notifications',
        description: 'This channel is used for default notifications',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: true,
      );

      // Retrieval request channel — used for locally-shown foreground notifications
      // and by the system when the FCM payload specifies this channel ID.
      final retrievalRequestChannel = AndroidNotificationChannel(
        'retrieval_request_channel',
        'Retrieval Requests',
        description: 'Notifications for valet retrieval requests',
        importance: Importance.max,
        playSound: true,
        sound: retrievalSound,
        enableVibration: true,
        vibrationPattern: retrievalVibrationPattern,
      );

      // The server sends retrieval pushes on Android channel `retrieval_requests`;
      // it must exist on the device or the OS falls back to a quiet default.
      final retrievalRequestsChannel = AndroidNotificationChannel(
        'retrieval_requests',
        'Retrieval Requests',
        description: 'Notifications for valet retrieval requests',
        importance: Importance.max,
        playSound: true,
        sound: retrievalSound,
        enableVibration: true,
        vibrationPattern: retrievalVibrationPattern,
      );

      // Driver updates channel
      const driverUpdatesChannel = AndroidNotificationChannel(
        'driver_updates_channel',
        'Driver Updates',
        description: 'Notifications for driver assignments and updates',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: true,
        // No sound parameter = uses default system notification sound
      );

      // System alerts channel
      const systemAlertsChannel = AndroidNotificationChannel(
        'system_alerts_channel',
        'System Alerts',
        description: 'Important system notifications and alerts',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        // No sound parameter = uses default system notification sound
      );

      // Register all channels
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(highPriorityChannel);

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(defaultChannel);

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(retrievalRequestChannel);

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(retrievalRequestsChannel);

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(driverUpdatesChannel);

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(systemAlertsChannel);

      log('Notification channels created successfully');
    } catch (e) {
      log('Error creating notification channels: $e');
    }
  }

  /// Show a notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    String? channelId,
    String? channelName,
    String? channelDescription,
    Importance importance = Importance.defaultImportance,
    Priority priority = Priority.defaultPriority,
  }) async {
    try {
      // Determine channel based on notification type
      final effectiveChannelId = channelId ?? _getChannelId(payload?['type']);
      final effectiveChannelName =
          channelName ?? _getChannelName(payload?['type']);
      final effectiveChannelDescription =
          channelDescription ?? _getChannelDescription(payload?['type']);

      // Create longer vibration pattern: [delay, vibrate, pause, vibrate, pause, vibrate, pause, vibrate, pause]
      // Pattern: 0ms delay, 2000ms vibrate, 500ms pause, 2000ms vibrate, 500ms pause, 2000ms vibrate, 500ms pause, 2000ms vibrate, 500ms pause
      // Total vibration: ~8 seconds (2000 + 500 + 2000 + 500 + 2000 + 500 + 2000 + 500)
      final vibrationPattern =
          Int64List.fromList([0, 2000, 500, 2000, 500, 2000, 500, 2000, 500]);

      // Use the custom retrieval-alert sound for retrieval_request notifications;
      // fall back to the default system sound for all other types.
      final isRetrieval = isRetrievalAlertType(payload?['type'] as String?);
      final notifSound = isRetrieval
          ? const RawResourceAndroidNotificationSound('retrieval_alert')
          : null;

      final androidDetails = AndroidNotificationDetails(
        effectiveChannelId,
        effectiveChannelName,
        channelDescription: effectiveChannelDescription,
        importance: importance,
        priority: priority,
        playSound: true,
        sound: notifSound,
        enableVibration: true,
        vibrationPattern: vibrationPattern,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
        ),
      );

      // iOS notification details — use the custom sound for retrieval requests.
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: isRetrieval ? 'retrieval_alert.mp3' : null,
      );

      // Combined notification details
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show notification
      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload != null ? jsonEncode(payload) : null,
      );

      log('Notification shown - ID: $id, Title: $title');
    } catch (e) {
      log('Error showing notification: $e');
    }
  }

  /// Show notification with action buttons
  Future<void> showNotificationWithActions({
    required int id,
    required String title,
    required String body,
    required List<AndroidNotificationAction> actions,
    Map<String, dynamic>? payload,
  }) async {
    try {
      // Create longer vibration pattern: [delay, vibrate, pause, vibrate, pause, vibrate, pause, vibrate, pause]
      // Pattern: 0ms delay, 2000ms vibrate, 500ms pause, 2000ms vibrate, 500ms pause, 2000ms vibrate, 500ms pause, 2000ms vibrate, 500ms pause
      // Total vibration: ~8 seconds (2000 + 500 + 2000 + 500 + 2000 + 500 + 2000 + 500)
      final vibrationPattern =
          Int64List.fromList([0, 2000, 500, 2000, 500, 2000, 500, 2000, 500]);

      final androidDetails = AndroidNotificationDetails(
        'high_priority_channel',
        'High Priority Notifications',
        channelDescription:
            'This channel is used for high priority notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: vibrationPattern,
        // No sound parameter = uses default system notification sound
        icon: '@mipmap/ic_launcher',
        actions: actions,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload != null ? jsonEncode(payload) : null,
      );

      log('Notification with actions shown - ID: $id');
    } catch (e) {
      log('Error showing notification with actions: $e');
    }
  }

  /// Schedule a notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    Map<String, dynamic>? payload,
  }) async {
    try {
      // This requires timezone package setup
      // For simplicity, showing immediate notification
      // TODO: Implement proper scheduling with timezone
      await showNotification(
        id: id,
        title: title,
        body: body,
        payload: payload,
      );

      log('Notification scheduled - ID: $id for $scheduledTime');
    } catch (e) {
      log('Error scheduling notification: $e');
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      log('Notification cancelled - ID: $id');
    } catch (e) {
      log('Error cancelling notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      log('All notifications cancelled');
    } catch (e) {
      log('Error cancelling all notifications: $e');
    }
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      log('Error getting pending notifications: $e');
      return [];
    }
  }

  /// Get active notifications
  Future<List<ActiveNotification>> getActiveNotifications() async {
    try {
      final activeNotifications = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.getActiveNotifications();
      return activeNotifications ?? [];
    } catch (e) {
      log('Error getting active notifications: $e');
      return [];
    }
  }

  /// Helper method to get channel ID based on notification type
  String _getChannelId(String? type) {
    switch (type) {
      case 'retrieval_request':
      case 'retrieval_assigned':
        return 'retrieval_request_channel';
      case 'driver_assigned':
      case 'driver_update':
        return 'driver_updates_channel';
      case 'system_alert':
        return 'system_alerts_channel';
      case 'vehicle_ready':
      case 'vehicle_delivered':
        return 'driver_updates_channel';
      default:
        return 'default_channel';
    }
  }

  /// Helper method to get channel name based on notification type
  String _getChannelName(String? type) {
    switch (type) {
      case 'retrieval_request':
      case 'retrieval_assigned':
        return 'Retrieval Requests';
      case 'driver_assigned':
      case 'driver_update':
        return 'Driver Updates';
      case 'system_alert':
        return 'System Alerts';
      default:
        return 'Default Notifications';
    }
  }

  /// Helper method to get channel description based on notification type
  String _getChannelDescription(String? type) {
    switch (type) {
      case 'retrieval_request':
      case 'retrieval_assigned':
        return 'Notifications for valet retrieval requests';
      case 'driver_assigned':
      case 'driver_update':
        return 'Notifications for driver assignments and updates';
      case 'system_alert':
        return 'Important system notifications and alerts';
      default:
        return 'General notifications';
    }
  }

  /// Callback for iOS notifications when app is in foreground
  static void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    log('iOS foreground notification - ID: $id, Title: $title');
  }

  /// Callback when notification is tapped
  static void _onNotificationTapped(NotificationResponse response) {
    log('Notification tapped - ID: ${response.id}, Action: ${response.actionId}');

    if (response.payload != null) {
      try {
        final payload = jsonDecode(response.payload!) as Map<String, dynamic>?;
        log('Notification payload: $payload');

        // Speak notification body aloud when user taps (loud, hearable TTS)
        if (payload != null) {
          final body = payload['body'] as String?;
          final title = payload['title'] as String?;
          final textToSpeak = body?.trim().isNotEmpty == true
              ? body!
              : title?.trim().isNotEmpty == true
                  ? title!
                  : null;
          if (textToSpeak != null) {
            TextToSpeechService().speak(textToSpeak);
          }
        }
      } catch (e) {
        log('Error parsing notification payload: $e');
      }
    }
  }
}
