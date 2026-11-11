import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:niloufer_valet_mobile/api/oauth/profile_api_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';
import 'package:niloufer_valet_mobile/services/websocket/websocket_service.dart';
import 'websocket_event.dart';
import 'websocket_state.dart';

/// A room the app wants to be subscribed to on the server.
class _Room {
  final String type;
  final String id;
  final Map<String, dynamic> extra;

  const _Room(this.type, this.id, [this.extra = const {}]);

  Map<String, dynamic> get payload => {
        ...extra,
        // The API expects a numeric id (e.g. outletId).
        '${type}Id': int.tryParse(id) ?? id,
      };
}

/// BLoC for managing WebSocket connection lifecycle
class WebSocketBloc extends Bloc<WebSocketEvent, WebSocketState> {
  final WebSocketService _webSocketService = WebSocketService();

  /// Rooms the app wants to be in. Re-subscribed on every (re)connect, because
  /// the server forgets a socket's room subscriptions when it drops.
  final Map<String, _Room> _desiredRooms = {};

  /// Rooms the server has confirmed for the current connection.
  final Set<String> _joinedRooms = {};

  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<void>? _readySubscription;
  StreamSubscription<Map<String, dynamic>>? _authErrorSubscription;
  final Map<String, StreamSubscription<dynamic>> _eventSubscriptions = {};

  // Store connection details for reconnection
  String? _lastUrl;
  Map<String, dynamic>? _lastQuery;
  Map<String, dynamic>? _lastAuth;

  // Track if we're currently refreshing token to avoid multiple refresh attempts
  bool _isRefreshingToken = false;

  /// Consecutive times the server closed the socket without it getting ready
  /// again. Caps the check-session-and-reconnect loop; reset once the server
  /// accepts a connection or the app connects afresh.
  int _serverDisconnectRetries = 0;
  static const int _maxServerDisconnectRetries = 3;

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
    on<_WebSocketServerReady>(_onServerReady);
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

  /// Get list of rooms the server has confirmed for this connection
  Set<String> get joinedRooms => Set.unmodifiable(_joinedRooms);

  /// Open the socket and (re)attach the status listeners.
  Future<void> _openConnection() {
    _connectionSubscription?.cancel();
    _connectionSubscription =
        _webSocketService.connectionStream.listen((isConnected) {
      if (isConnected) {
        add(const _WebSocketConnectionEstablished());
      } else {
        add(const _WebSocketConnectionLost());
      }
    });

    _readySubscription?.cancel();
    _readySubscription = _webSocketService.readyStream.listen((_) {
      add(const _WebSocketServerReady());
    });

    return _webSocketService.connect(
      url: _lastUrl!,
      auth: _lastAuth,
      query: _lastQuery,
      // Read the token afresh on every handshake, including automatic
      // reconnects, instead of reusing the one captured here.
      tokenProvider: TokenStorage.getAccessToken,
      autoConnect: true,
    );
  }

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
      _serverDisconnectRetries = 0;

      await _openConnection();

      // Wait a bit for connection to establish
      await Future.delayed(const Duration(milliseconds: 500));

      if (_webSocketService.isConnected) {
        final socketId = _webSocketService.socket?.id ?? 'unknown';
        print('WebSocket connected with ID: $socketId');
        emit(WebSocketConnected(
          socketId: socketId,
          joinedRooms: _joinedRooms.toList(),
        ));
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

      // Cancel connection subscriptions
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;
      await _readySubscription?.cancel();
      _readySubscription = null;

      // This is a deliberate disconnect (logout): forget the rooms too
      _desiredRooms.clear();
      _joinedRooms.clear();
      _serverDisconnectRetries = 0;

      // Disconnect and close event streams
      await _webSocketService.disconnect(closeEventStreams: true);

      emit(const WebSocketDisconnected(reason: 'User disconnected'));
    } catch (e) {
      print('Error disconnecting from WebSocket: $e');
      emit(WebSocketError(message: 'Disconnect failed', error: e));
    }
  }

  /// Subscribe to a room on the server. Returns true only if the server
  /// accepted it. A timeout is retried; an explicit rejection is not.
  Future<bool> _subscribe(_Room room) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      if (!_webSocketService.isConnected) return false;
      try {
        final response = await _webSocketService.emitWithAck(
          'subscribe:${room.type}',
          room.payload,
          const Duration(seconds: 5),
        );
        // Acks can arrive wrapped in a list of arguments.
        final result =
            response is List && response.isNotEmpty ? response.first : response;
        if (result is Map && result['success'] == true) return true;
        print('Subscription to ${room.type}:${room.id} rejected: $result');
        return false;
      } on TimeoutException {
        print('Subscription to ${room.type}:${room.id} timed out '
            '(attempt ${attempt + 1})');
      } catch (e) {
        print('Subscription to ${room.type}:${room.id} failed: $e');
        return false;
      }
    }
    return false;
  }

  /// Join a room
  Future<void> _onJoinRoom(
    JoinRoom event,
    Emitter<WebSocketState> emit,
  ) async {
    final roomName = event.roomName;
    final room = _Room(
      event.roomType,
      event.roomId,
      Map<String, dynamic>.from(event.additionalData ?? const {}),
    );

    // Remember the room first so it is subscribed as soon as the server is
    // ready, or again after any reconnect.
    _desiredRooms[roomName] = room;

    if (!_webSocketService.isReady) {
      // The server is not ready to take subscriptions yet (or we are offline);
      // _onServerReady will subscribe once it is.
      print('Room $roomName queued until the server is ready');
      return;
    }

    if (await _subscribe(room)) {
      _joinedRooms.add(roomName);
      if (!emit.isDone && state is WebSocketConnected) {
        emit((state as WebSocketConnected).copyWith(
          joinedRooms: _joinedRooms.toList(),
        ));
      }
    }
  }

  /// Leave a room
  Future<void> _onLeaveRoom(
    LeaveRoom event,
    Emitter<WebSocketState> emit,
  ) async {
    final roomName = event.roomName;

    // Stop wanting the room even if offline, so it is not re-joined later.
    _desiredRooms.remove(roomName);
    final wasJoined = _joinedRooms.remove(roomName);

    if (_webSocketService.isConnected) {
      _webSocketService.emit('unsubscribe:${event.roomType}', {
        '${event.roomType}Id': int.tryParse(event.roomId) ?? event.roomId,
      });
    }

    if (wasJoined && state is WebSocketConnected) {
      emit((state as WebSocketConnected).copyWith(
        joinedRooms: _joinedRooms.toList(),
      ));
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
    // The server drops a socket's room subscriptions with it.
    _joinedRooms.clear();
    emit(const WebSocketDisconnected(reason: 'Connection lost'));
  }

  /// The server accepted this connection: subscribe to every wanted room.
  /// Runs on the first connect and after every reconnect.
  Future<void> _onServerReady(
    _WebSocketServerReady event,
    Emitter<WebSocketState> emit,
  ) async {
    _serverDisconnectRetries = 0;
    _joinedRooms.clear();

    for (final entry in _desiredRooms.entries.toList()) {
      if (await _subscribe(entry.value)) {
        _joinedRooms.add(entry.key);
        print('Joined room: ${entry.key}');
      }
    }

    if (emit.isDone || !_webSocketService.isConnected) return;
    final socketId = _webSocketService.socket?.id ?? 'unknown';
    emit(WebSocketConnected(
        socketId: socketId, joinedRooms: _joinedRooms.toList()));
  }

  /// Reconnect when app returns from background (uses stored url/auth/query).
  Future<void> _onReconnectWebSocket(
    ReconnectWebSocket event,
    Emitter<WebSocketState> emit,
  ) async {
    if (_lastUrl == null || _lastUrl!.isEmpty) {
      return;
    }
    if (_webSocketService.isConnected || _isRefreshingToken) {
      return;
    }
    // The token is read afresh on connect, so this picks up any new session.
    add(ConnectWebSocket(
      url: _lastUrl!,
      auth: _lastAuth,
      query: _lastQuery,
    ));
  }

  /// The server closed the socket (token refused or session ended) or reported
  /// an auth error. Check the session is still alive, then reconnect with the
  /// current token.
  Future<void> _onRefreshTokenAndReconnect(
    _WebSocketRefreshTokenAndReconnect event,
    Emitter<WebSocketState> emit,
  ) async {
    // Prevent multiple simultaneous refresh attempts
    if (_isRefreshingToken) {
      print('Token refresh already in progress, skipping');
      return;
    }
    if (_lastUrl == null || _lastUrl!.isEmpty) {
      return;
    }
    if (_serverDisconnectRetries >= _maxServerDisconnectRetries) {
      print('WebSocket keeps being closed by the server, giving up for now');
      return;
    }

    _isRefreshingToken = true;
    _serverDisconnectRetries++;

    try {
      print('Checking session before WebSocket reconnection...');

      // No refresh token exists: confirm the session is still alive. A 401
      // ends the session (handled in the HTTP layer) and throws here.
      await ProfileApiService.getProfile();

      final accessToken = await TokenStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('No access token available to reconnect WebSocket');
      }

      // Keep the stored details current for later reconnects.
      _lastAuth = {...?_lastAuth, 'token': accessToken};
      if (_lastQuery?.containsKey('token') ?? false) {
        _lastQuery = {...?_lastQuery, 'token': accessToken};
      }

      // Back off a little more on each consecutive attempt.
      await Future.delayed(
          Duration(milliseconds: 500 * _serverDisconnectRetries));

      await _openConnection();

      // Rooms are re-subscribed by _onServerReady once the server accepts
      // the new connection.
      print('WebSocket reconnecting with current token');
    } catch (e) {
      print('Error checking session and reconnecting WebSocket: $e');
      if (!emit.isDone) {
        emit(WebSocketError(
            message: 'Token refresh failed',
            error: getDisplayErrorMessage(e)));
      }
    } finally {
      _isRefreshingToken = false;
    }
  }

  @override
  Future<void> close() async {
    // Cancel all subscriptions
    await _connectionSubscription?.cancel();
    await _readySubscription?.cancel();
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

class _WebSocketServerReady extends WebSocketEvent {
  const _WebSocketServerReady();
}

class _WebSocketRefreshTokenAndReconnect extends WebSocketEvent {
  const _WebSocketRefreshTokenAndReconnect();
}
