import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:niloufer_valet_mobile/api/oauth/refresh_api_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';
import 'package:niloufer_valet_mobile/services/websocket/websocket_service.dart';
import 'websocket_event.dart';
import 'websocket_state.dart';

/// BLoC for managing WebSocket connection lifecycle
class WebSocketBloc extends Bloc<WebSocketEvent, WebSocketState> {
  final WebSocketService _webSocketService = WebSocketService();
  final Set<String> _joinedRooms = {};
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<Map<String, dynamic>>? _authErrorSubscription;
  final Map<String, StreamSubscription<dynamic>> _eventSubscriptions = {};

  // Store connection details for reconnection
  String? _lastUrl;
  Map<String, dynamic>? _lastQuery;
  Map<String, dynamic>? _lastAuth;

  // Track if we're currently refreshing token to avoid multiple refresh attempts
  bool _isRefreshingToken = false;

  WebSocketBloc() : super(const WebSocketInitial()) {
    on<ConnectWebSocket>(_onConnectWebSocket);
    on<DisconnectWebSocket>(_onDisconnectWebSocket);
    on<ReconnectWebSocket>(_onReconnectWebSocket);
    on<JoinRoom>(_onJoinRoom);
    on<LeaveRoom>(_onLeaveRoom);
    on<ListenToEvent>(_onListenToEvent);
    on<StopListeningToEvent>(_onStopListeningToEvent);
    on<EmitEvent>(_onEmitEvent);
    on<_WebSocketConnectionEstablished>(_onConnectionEstablished);
    on<_WebSocketConnectionLost>(_onConnectionLost);
    on<_WebSocketRefreshTokenAndReconnect>(_onRefreshTokenAndReconnect);

    // Setup auth error listener
    _setupAuthErrorListener();
  }

  /// Setup listener for authentication errors
  void _setupAuthErrorListener() {
    _authErrorSubscription = _webSocketService.authErrorStream.listen((error) {
      print('Auth error detected in WebSocket, triggering token refresh');
      add(const _WebSocketRefreshTokenAndReconnect());
    });
  }

  /// Get WebSocket service instance for direct access if needed
  WebSocketService get service => _webSocketService;

  /// Check if connected
  bool get isConnected => _webSocketService.isConnected;

  /// Get list of joined rooms
  Set<String> get joinedRooms => Set.unmodifiable(_joinedRooms);

  /// Connect to WebSocket server
  Future<void> _onConnectWebSocket(
    ConnectWebSocket event,
    Emitter<WebSocketState> emit,
  ) async {
    try {
      emit(const WebSocketConnecting());

      // Store connection details for potential reconnection
      _lastUrl = event.url;
      _lastQuery = event.query;
      _lastAuth = event.auth;

      // Connect to WebSocket
      await _webSocketService.connect(
        url: event.url,
        auth: event.auth,
        query: event.query,
        autoConnect: true,
      );

      // Listen to connection status changes
      _connectionSubscription?.cancel();
      _connectionSubscription =
          _webSocketService.connectionStream.listen((isConnected) {
        if (isConnected) {
          add(const _WebSocketConnectionEstablished());
        } else {
          add(const _WebSocketConnectionLost());
        }
      });

      // Wait a bit for connection to establish
      await Future.delayed(const Duration(milliseconds: 500));

      if (_webSocketService.isConnected) {
        final socketId = _webSocketService.socket?.id ?? 'unknown';
        print('WebSocket connected with ID: $socketId');
        emit(WebSocketConnected(socketId: socketId));
      }
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      emit(WebSocketError(message: 'Connection failed', error: e));
    }
  }

  /// Disconnect from WebSocket server
  Future<void> _onDisconnectWebSocket(
    DisconnectWebSocket event,
    Emitter<WebSocketState> emit,
  ) async {
    try {
      // Cancel all event subscriptions
      for (var subscription in _eventSubscriptions.values) {
        await subscription.cancel();
      }
      _eventSubscriptions.clear();

      // Cancel connection subscription
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;

      // Clear joined rooms
      _joinedRooms.clear();

      // Disconnect
      await _webSocketService.disconnect();

      emit(const WebSocketDisconnected(reason: 'User disconnected'));
    } catch (e) {
      print('Error disconnecting from WebSocket: $e');
      emit(WebSocketError(message: 'Disconnect failed', error: e));
    }
  }

  /// Join a room
  Future<void> _onJoinRoom(
    JoinRoom event,
    Emitter<WebSocketState> emit,
  ) async {
    if (!_webSocketService.isConnected) {
      print('Cannot join room: WebSocket not connected');
      return;
    }

    try {
      final roomName = event.roomName;
      // Emit subscribe event based on room type (matches NestJS @SubscribeMessage)
      final payload = event.additionalData ?? {};
      payload['${event.roomType}Id'] = event.roomId;

      // Use emitWithAck to get server confirmation
      try {
        await _webSocketService.emitWithAck(
          'subscribe:${event.roomType}',
          payload,
          const Duration(seconds: 5),
        );
      } catch (e) {
        print('No response from subscription (continuing anyway): $e');
      }

      // Track joined room
      _joinedRooms.add(roomName);

      // Update state with joined room
      if (state is WebSocketConnected) {
        final currentState = state as WebSocketConnected;
        emit(currentState.copyWith(
          joinedRooms: _joinedRooms.toList(),
        ));
      }
    } catch (e) {
      print('Error joining room: $e');
    }
  }

  /// Leave a room
  Future<void> _onLeaveRoom(
    LeaveRoom event,
    Emitter<WebSocketState> emit,
  ) async {
    if (!_webSocketService.isConnected) {
      print('Cannot leave room: WebSocket not connected');
      return;
    }

    try {
      final roomName = event.roomName;
      // Emit unsubscribe event based on room type (matches NestJS @SubscribeMessage)
      _webSocketService.emit('unsubscribe:${event.roomType}', {
        '${event.roomType}Id': event.roomId,
      });

      // Remove from tracked rooms
      _joinedRooms.remove(roomName);

      // Update state with updated room list
      if (state is WebSocketConnected) {
        final currentState = state as WebSocketConnected;
        emit(currentState.copyWith(
          joinedRooms: _joinedRooms.toList(),
        ));
      }
    } catch (e) {
      print('Error leaving room: $e');
    }
  }

  /// Listen to a specific event
  Future<void> _onListenToEvent(
    ListenToEvent event,
    Emitter<WebSocketState> emit,
  ) async {
    if (_eventSubscriptions.containsKey(event.eventName)) {
      return;
    }

    try {
      final stream = _webSocketService.getEventStream(event.eventName);
      final subscription = stream.listen(
        (data) {
          // Events are handled by listeners in the app, not by the BLoC
        },
        onError: (error) {
          print('Error on event ${event.eventName}: $error');
        },
      );

      _eventSubscriptions[event.eventName] = subscription;
    } catch (e) {
      print('Error setting up listener for ${event.eventName}: $e');
    }
  }

  /// Stop listening to a specific event
  Future<void> _onStopListeningToEvent(
    StopListeningToEvent event,
    Emitter<WebSocketState> emit,
  ) async {
    if (!_eventSubscriptions.containsKey(event.eventName)) {
      return;
    }

    try {
      await _eventSubscriptions[event.eventName]?.cancel();
      _eventSubscriptions.remove(event.eventName);

      _webSocketService.disposeEventStream(event.eventName);
    } catch (e) {
      print('Error stopping listener for ${event.eventName}: $e');
    }
  }

  /// Emit an event to the server
  Future<void> _onEmitEvent(
    EmitEvent event,
    Emitter<WebSocketState> emit,
  ) async {
    if (!_webSocketService.isConnected) {
      print('Cannot emit event: WebSocket not connected');
      return;
    }

    try {
      _webSocketService.emit(event.eventName, event.data);
    } catch (e) {
      print('Error emitting event ${event.eventName}: $e');
    }
  }

  /// Handle connection established
  Future<void> _onConnectionEstablished(
    _WebSocketConnectionEstablished event,
    Emitter<WebSocketState> emit,
  ) async {
    final socketId = _webSocketService.socket?.id ?? 'unknown';
    emit(WebSocketConnected(
        socketId: socketId, joinedRooms: _joinedRooms.toList()));
  }

  /// Handle connection lost
  Future<void> _onConnectionLost(
    _WebSocketConnectionLost event,
    Emitter<WebSocketState> emit,
  ) async {
    emit(const WebSocketDisconnected(reason: 'Connection lost'));
  }

  /// Reconnect when app returns from background (uses stored url/auth/query).
  Future<void> _onReconnectWebSocket(
    ReconnectWebSocket event,
    Emitter<WebSocketState> emit,
  ) async {
    if (_lastUrl == null || _lastUrl!.isEmpty) {
      return;
    }
    if (_webSocketService.isConnected) {
      return;
    }
    add(ConnectWebSocket(
      url: _lastUrl!,
      auth: _lastAuth,
      query: _lastQuery,
    ));
  }

  /// Refresh token and reconnect to WebSocket
  Future<void> _onRefreshTokenAndReconnect(
    _WebSocketRefreshTokenAndReconnect event,
    Emitter<WebSocketState> emit,
  ) async {
    // Prevent multiple simultaneous refresh attempts
    if (_isRefreshingToken) {
      print('Token refresh already in progress, skipping');
      return;
    }

    _isRefreshingToken = true;

    try {
      print('Refreshing access token for WebSocket reconnection...');

      // Refresh the token
      await RefreshApiService.refreshToken();

      // Get the new access token
      final newAccessToken = await TokenStorage.getAccessToken();
      if (newAccessToken == null || newAccessToken.isEmpty) {
        throw Exception('Failed to get new access token after refresh');
      }

      print('Token refreshed successfully, reconnecting WebSocket...');

      // Disconnect the old connection
      await _webSocketService.disconnect();

      // Small delay before reconnecting
      await Future.delayed(const Duration(milliseconds: 500));

      // Update query with new token
      final updatedQuery = Map<String, dynamic>.from(_lastQuery ?? {});
      updatedQuery['token'] = newAccessToken;

      // Reconnect with new token
      await _webSocketService.connect(
        url: _lastUrl!,
        auth: _lastAuth,
        query: updatedQuery,
        autoConnect: true,
      );

      // Update stored query for future reconnections
      _lastQuery = updatedQuery;

      print('WebSocket reconnected with new token');

      // Re-join all previously joined rooms
      if (_joinedRooms.isNotEmpty) {
        print('Re-joining ${_joinedRooms.length} rooms after reconnection');
        await Future.delayed(const Duration(milliseconds: 500));

        for (final roomName in _joinedRooms.toList()) {
          // Parse room name to extract type and id
          final parts = roomName.split(':');
          if (parts.length == 2) {
            final roomType = parts[0];
            final roomId = parts[1];

            final payload = <String, dynamic>{};
            payload['${roomType}Id'] = roomId;

            try {
              await _webSocketService.emitWithAck(
                'subscribe:$roomType',
                payload,
                const Duration(seconds: 5),
              );
              print('Re-joined room: $roomName');
            } catch (e) {
              print('Failed to re-join room $roomName: $e');
            }
          }
        }
      }

      if (_webSocketService.isConnected) {
        final socketId = _webSocketService.socket?.id ?? 'unknown';
        emit(WebSocketConnected(
            socketId: socketId, joinedRooms: _joinedRooms.toList()));
      }
    } catch (e) {
      print('Error refreshing token and reconnecting: $e');
      emit(
          WebSocketError(message: 'Token refresh failed', error: getDisplayErrorMessage(e)));
    } finally {
      _isRefreshingToken = false;
    }
  }

  @override
  Future<void> close() async {
    // Cancel all subscriptions
    await _connectionSubscription?.cancel();
    await _authErrorSubscription?.cancel();
    for (var subscription in _eventSubscriptions.values) {
      await subscription.cancel();
    }
    _eventSubscriptions.clear();

    return super.close();
  }
}

// Internal events for connection state changes
class _WebSocketConnectionEstablished extends WebSocketEvent {
  const _WebSocketConnectionEstablished();
}

class _WebSocketConnectionLost extends WebSocketEvent {
  const _WebSocketConnectionLost();
}

class _WebSocketRefreshTokenAndReconnect extends WebSocketEvent {
  const _WebSocketRefreshTokenAndReconnect();
}
