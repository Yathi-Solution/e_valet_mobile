import 'dart:async';

import 'package:niloufer_valet_mobile/bloc/websocket/websocket_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/websocket/websocket_event.dart';
import 'package:niloufer_valet_mobile/api/core/api_config.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';

/// Helper class to manage WebSocket lifecycle during app flow
class WebSocketHelper {
  /// Initialize WebSocket connection after login
  /// Call this after successful login or when restoring session from cache
  static Future<void> connectAfterLogin({
    required WebSocketBloc webSocketBloc,
    String? outletId,
    String? driverId,
    String? operatorId,
    Duration? initialDelay,
  }) async {
    try {
      // Add a small delay to ensure everything is initialized
      // This helps avoid race conditions on first app launch
      await Future.delayed(initialDelay ?? const Duration(milliseconds: 500));

      // Get access token
      final accessToken = await TokenStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('Cannot connect WebSocket: No access token');
        return;
      }

      // Get base URL and construct WebSocket URL
      final baseUrl = ApiConfig.websocketBaseUrl;
      if (baseUrl.isEmpty) {
        print('Cannot connect WebSocket: Base URL is empty');
        return;
      }

      print('Attempting to connect WebSocket to: $baseUrl');

      final notificationsUrl = baseUrl;

      // Connect to WebSocket with authentication
      // The server reads the Client token from auth.token (or the
      // Authorization header, which the service also sets from the query token).
      webSocketBloc.add(ConnectWebSocket(
        url: notificationsUrl,
        auth: {'token': accessToken},
        query: {'token': accessToken},
      ));

      // Wait for connection to actually establish by listening to connection stream
      final connectionCompleter = Completer<void>();
      late final StreamSubscription connectionSubscription;
      Timer? timeoutTimer;

      connectionSubscription =
          webSocketBloc.service.connectionStream.listen((isConnected) {
        if (isConnected && !connectionCompleter.isCompleted) {
          print('WebSocket connected successfully');
          connectionCompleter.complete();
          timeoutTimer?.cancel();
          connectionSubscription.cancel();
        }
      });

      // Set up timeout timer
      timeoutTimer = Timer(const Duration(seconds: 15), () {
        if (!connectionCompleter.isCompleted) {
          print(
              'WebSocket connection timeout after 15 seconds - continuing anyway');
          connectionCompleter.complete();
          connectionSubscription.cancel();
        }
      });

      // Wait for connection (or timeout)
      try {
        await connectionCompleter.future;
      } catch (e) {
        print('Error waiting for WebSocket connection: $e');
        connectionSubscription.cancel();
        timeoutTimer.cancel();
      }

      // Small delay before joining rooms
      await Future.delayed(const Duration(milliseconds: 300));

      // Join outlet room only (driver/operator rooms are auto-joined by backend based on user roles)
      if (outletId != null && webSocketBloc.service.isConnected) {
        print('Joining outlet room: $outletId');
        webSocketBloc.add(JoinRoom.outlet(outletId));
      }
    } catch (e) {
      print('Error connecting WebSocket after login: $e');
    }
  }

  /// Disconnect WebSocket on logout
  /// Call this before clearing auth tokens during logout
  static Future<void> disconnectOnLogout({
    required WebSocketBloc webSocketBloc,
  }) async {
    try {
      // Disconnect from WebSocket
      webSocketBloc.add(const DisconnectWebSocket());

      // Wait a moment for cleanup
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      print('Error disconnecting WebSocket on logout: $e');
    }
  }

  /// Join additional rooms dynamically (e.g., when outlet changes)
  static void joinRoom({
    required WebSocketBloc webSocketBloc,
    required String roomType,
    required String roomId,
  }) {
    try {
      switch (roomType) {
        case 'outlet':
          webSocketBloc.add(JoinRoom.outlet(roomId));
          break;
        default:
          print('Unknown room type: $roomType');
      }
    } catch (e) {
      print('Error joining room: $e');
    }
  }

  /// Leave a room dynamically
  static void leaveRoom({
    required WebSocketBloc webSocketBloc,
    required String roomType,
    required String roomId,
  }) {
    try {
      switch (roomType) {
        case 'outlet':
          webSocketBloc.add(LeaveRoom.outlet(roomId));
          break;
        default:
          print('Unknown room type: $roomType');
      }
    } catch (e) {
      print('Error leaving room: $e');
    }
  }
}
