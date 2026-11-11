import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

/// WebSocket service for managing Socket.IO connections
class WebSocketService {
  /// Singleton instance
  static final WebSocketService _instance = WebSocketService._internal();

  factory WebSocketService() => _instance;

  WebSocketService._internal();

  /// Socket instance
  io.Socket? _socket;

  /// Connection status stream
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  /// Authentication error stream
  final StreamController<Map<String, dynamic>> _authErrorController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Fires each time the server finishes authenticating a connection (its
  /// `connected` event). Rooms can only be subscribed to after this.
  final StreamController<void> _readyController =
      StreamController<void>.broadcast();

  /// Custom event stream controllers for dynamic event handling. They outlive
  /// any single socket: each new socket is re-bound to them (see
  /// [_bindEventHandlers]), so subscribers keep receiving events after a
  /// reconnect.
  final Map<String, StreamController<dynamic>> _eventControllers = {};

  /// True once the server has acknowledged the current connection.
  bool _ready = false;

  /// Get the socket instance
  io.Socket? get socket => _socket;

  /// Check if socket is connected
  bool get isConnected => _socket?.connected ?? false;

  /// True when connected and the server has accepted the connection's token.
  bool get isReady => isConnected && _ready;

  /// Stream that fires on every server-side "connected" acknowledgement.
  Stream<void> get readyStream => _readyController.stream;

  /// Stream to listen to connection status changes
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Stream to listen to authentication errors
  Stream<Map<String, dynamic>> get authErrorStream =>
      _authErrorController.stream;

  /// Initialize and connect to WebSocket server.
  ///
  /// [tokenProvider], when given, is asked for the access token on every
  /// handshake (including automatic reconnects), so a reconnect never reuses a
  /// stale token. [auth] is the fallback / static auth payload.
  ///
  /// [reconnectionAttempts] defaults to unlimited: a phone on a flaky network
  /// should keep retrying rather than give up after a few tries.
  Future<void> connect({
    required String url,
    Map<String, dynamic>? query,
    Map<String, dynamic>? auth,
    Future<String?> Function()? tokenProvider,
    bool autoConnect = true,
    int? reconnectionAttempts,
    int reconnectionDelay = 2000,
    int reconnectionDelayMax = 10000,
    int timeout = 20000,
  }) async {
    try {
      // Always drop the previous socket, connected or not. A socket that is
      // disconnected or mid-retry would otherwise keep retrying in the
      // background alongside the new one.
      _teardownSocket();

      print('Connecting to WebSocket: $url');

      // Build socket options
      final optionBuilder = io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setReconnectionDelay(reconnectionDelay)
          .setReconnectionDelayMax(reconnectionDelayMax)
          .setTimeout(timeout)
          .enableForceNew()
          .enableReconnection();

      if (reconnectionAttempts != null) {
        optionBuilder.setReconnectionAttempts(reconnectionAttempts);
      }

      // Add query parameters if provided
      if (query != null && query.isNotEmpty) {
        optionBuilder.setQuery(query);

        // If query contains 'token', also add it as Authorization header
        if (query.containsKey('token')) {
          final token = query['token'];
          optionBuilder.setExtraHeaders({
            'Authorization': 'Bearer $token',
          });
        }
      }

      // The server reads `auth.token` first, so that is the one that must be
      // current on every (re)connect.
      if (tokenProvider != null) {
        final fallbackToken = auth?['token']?.toString();
        optionBuilder.setAuthFn((callback) async {
          String? token;
          try {
            token = await tokenProvider();
          } catch (e) {
            print('Could not read access token for WebSocket handshake: $e');
          }
          callback({
            ...?auth,
            'token': (token != null && token.isNotEmpty) ? token : fallbackToken,
          });
        });
      } else if (auth != null && auth.isNotEmpty) {
        optionBuilder.setAuth(auth);
      }

      // Configure socket
      _socket = io.io(url, optionBuilder.build());

      // Setup default event listeners and re-bind existing event streams
      _setupDefaultListeners();
      _bindEventHandlers();

      // Connect if autoConnect is true
      if (autoConnect) {
        print('Auto-connecting socket...');
        _socket!.connect();
      }
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      rethrow;
    }
  }

  /// Setup default socket event listeners
  void _setupDefaultListeners() {
    final socket = _socket;
    if (socket == null) return;

    // Ignore callbacks from a socket that has since been replaced.
    bool isCurrent() => identical(socket, _socket);

    socket.onConnect((_) {
      if (!isCurrent()) return;
      print('WebSocket connected successfully');
      _connectionController.add(true);
    });

    // The server emits `connected` once it has verified the token and put the
    // socket in its user room. Subscriptions sent before this can be rejected.
    socket.on('connected', (_) {
      if (!isCurrent()) return;
      _ready = true;
      if (!_readyController.isClosed) _readyController.add(null);
    });

    socket.onDisconnect((data) {
      if (!isCurrent()) return;
      print('WebSocket disconnected: $data');
      _ready = false;
      _connectionController.add(false);

      // The server closes the socket itself when the token is not accepted or
      // the session has ended. socket.io does not retry those on its own, so
      // surface it for the owner to re-check the session and reconnect.
      if (data == 'io server disconnect' && !_authErrorController.isClosed) {
        _authErrorController.add({
          'error': 'io server disconnect',
          'statusCode': null,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });

    _socket?.onConnectError((error) {
      print('WebSocket connection error: $error');
      _connectionController.add(false);

      // Check if error is authentication-related
      _checkAndHandleAuthError(error);
    });

    _socket?.onConnectTimeout((_) {
      print('WebSocket connection timeout');
      _connectionController.add(false);
    });

    _socket?.onError((error) {
      print('WebSocket error: $error');

      // Check if error is authentication-related
      _checkAndHandleAuthError(error);
    });

    _socket?.onReconnect((attempt) {
      print('WebSocket reconnecting (attempt: $attempt)');
    });

    _socket?.onReconnectAttempt((attempt) {
      print('WebSocket reconnection attempt: $attempt');
    });

    _socket?.onReconnectError((error) {
      print('WebSocket reconnection error: $error');
    });

    _socket?.onReconnectFailed((_) {
      print('WebSocket reconnection failed - giving up');
      _connectionController.add(false);
    });

    _socket?.onPing((_) {
      // Uncomment for debugging
      // print('WebSocket ping');
    });

    _socket?.onPong((_) {
      // Uncomment for debugging
      // print('WebSocket pong');
    });

    // Listen to custom 'exception' event from server (NestJS gateway exception filter)
    _socket?.on('exception', (data) {
      print('WebSocket exception from server: $data');
      _checkAndHandleAuthError(data);
    });
  }

  /// Check if error is authentication-related and emit to auth error stream
  void _checkAndHandleAuthError(dynamic error) {
    try {
      String errorMessage = '';
      int? statusCode;

      if (error is Map) {
        errorMessage = error['message']?.toString() ?? '';
        statusCode = error['statusCode'] as int?;
      } else if (error is String) {
        errorMessage = error;
      }

      // Check for authentication error indicators
      final isAuthError = statusCode == 401 ||
          statusCode == 403 ||
          errorMessage.toLowerCase().contains('unauthorized') ||
          errorMessage.toLowerCase().contains('authentication') ||
          errorMessage.toLowerCase().contains('token') ||
          errorMessage.toLowerCase().contains('forbidden');

      if (isAuthError) {
        print('Authentication error detected in WebSocket: $errorMessage');
        if (!_authErrorController.isClosed) {
          _authErrorController.add({
            'error': errorMessage,
            'statusCode': statusCode,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      print('Error checking auth error: $e');
    }
  }

  /// Emit an event to the server
  void emit(String event, [dynamic data]) {
    if (_socket == null || !_socket!.connected) {
      print('Cannot emit event "$event": Socket not connected');
      return;
    }

    _socket!.emit(event, data);
  }

  /// Emit an event and wait for acknowledgment
  Future<dynamic> emitWithAck(
    String event, [
    dynamic data,
    Duration timeout = const Duration(seconds: 10),
  ]) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket not connected');
    }

    final completer = Completer<dynamic>();

    _socket!.emitWithAck(event, data, ack: (response) {
      if (!completer.isCompleted) {
        completer.complete(response);
      }
    });

    // Add timeout
    Future.delayed(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException(
          'Timeout waiting for acknowledgment on event: $event',
        ));
      }
    });

    return completer.future;
  }

  /// Listen to a specific event
  void on(String event, Function(dynamic) callback) {
    if (_socket == null) {
      print('Cannot listen to event "$event": Socket not initialized');
      return;
    }

    _socket!.on(event, callback);
  }

  /// Listen to a specific event once
  void once(String event, Function(dynamic) callback) {
    if (_socket == null) {
      print('Cannot listen to event "$event": Socket not initialized');
      return;
    }

    _socket!.once(event, callback);
  }

  /// Remove listener for a specific event
  void off(String event, [Function(dynamic)? callback]) {
    if (_socket == null) {
      print('Cannot remove listener for "$event": Socket not initialized');
      return;
    }

    if (callback != null) {
      _socket!.off(event, callback);
    } else {
      _socket!.off(event);
    }
  }

  /// Get a stream for a specific event
  ///
  /// The stream survives reconnects: it is re-bound to every new socket.
  Stream<dynamic> getEventStream(String event) {
    var controller = _eventControllers[event];
    if (controller == null || controller.isClosed) {
      controller = StreamController<dynamic>.broadcast();
      _eventControllers[event] = controller;
      final socket = _socket;
      if (socket != null) _bindEvent(socket, event, controller);
    }
    return controller.stream;
  }

  void _bindEvent(
    io.Socket socket,
    String event,
    StreamController<dynamic> controller,
  ) {
    socket.on(event, (data) {
      if (!controller.isClosed) controller.add(data);
    });
  }

  /// Attach every registered event stream to the current socket.
  void _bindEventHandlers() {
    final socket = _socket;
    if (socket == null) return;
    _eventControllers.forEach((event, controller) {
      _bindEvent(socket, event, controller);
    });
  }

  /// Dispose event stream
  void disposeEventStream(String event) {
    final controller = _eventControllers.remove(event);
    if (controller != null) {
      controller.close();
      _socket?.off(event);
    }
  }

  /// Manually connect the socket
  void manualConnect() {
    if (_socket == null) {
      print('Cannot connect: Socket not initialized');
      return;
    }

    if (!_socket!.connected) {
      _socket!.connect();
    } else {
      print('Socket already connected');
    }
  }

  /// Close and discard the current socket without touching the event streams.
  void _teardownSocket() {
    final socket = _socket;
    if (socket == null) return;
    // Clear first so the old socket's disconnect callback is ignored.
    _socket = null;
    _ready = false;
    socket.disconnect();
    socket.dispose();
  }

  /// Disconnect the socket.
  ///
  /// Event streams are kept by default so subscribers survive a reconnect.
  /// Pass [closeEventStreams] (e.g. on logout) to close them as well.
  Future<void> disconnect({bool closeEventStreams = false}) async {
    if (closeEventStreams) {
      for (var controller in _eventControllers.values) {
        if (!controller.isClosed) {
          await controller.close();
        }
      }
      _eventControllers.clear();
    }

    if (_socket == null) {
      print('Socket already null');
      return;
    }

    _teardownSocket();
    _connectionController.add(false);
  }

  /// Dispose the service and clean up resources
  Future<void> dispose() async {
    await disconnect(closeEventStreams: true);
    if (!_connectionController.isClosed) {
      await _connectionController.close();
    }
    if (!_authErrorController.isClosed) {
      await _authErrorController.close();
    }
    if (!_readyController.isClosed) {
      await _readyController.close();
    }
  }

  /// Reconnect the existing socket, keeping its options and event streams.
  void reconnect() {
    final socket = _socket;
    if (socket == null) {
      print('Cannot reconnect: Socket not initialized');
      return;
    }
    socket.disconnect();
    socket.connect();
  }

  /// Join a room (for Socket.IO room-based events)
  void joinRoom(String roomName, {Map<String, dynamic>? data}) {
    if (_socket == null || !_socket!.connected) {
      print('Cannot join room "$roomName": Socket not connected');
      return;
    }

    final payload = data ?? {};
    payload['room'] = roomName;
    emit('join_room', payload);
  }

  /// Leave a room (for Socket.IO room-based events)
  void leaveRoom(String roomName) {
    if (_socket == null || !_socket!.connected) {
      print('Cannot leave room "$roomName": Socket not connected');
      return;
    }

    emit('leave_room', {'room': roomName});
  }
}
