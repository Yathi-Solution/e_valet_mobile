import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:evalet/api/driver/assigned_sessions_api_service.dart';
import 'package:evalet/bloc/websocket/websocket_bloc.dart';
import 'package:evalet/models/driver/session/assigned_session.dart';
import 'package:evalet/utils/assigned_sessions_fifo.dart';

part 'assigned_sessions_background_event.dart';
part 'assigned_sessions_background_state.dart';

class AssignedSessionsBackgroundBloc extends Bloc<
    AssignedSessionsBackgroundEvent, AssignedSessionsBackgroundState> {
  final WebSocketBloc? webSocketBloc;
  StreamSubscription<dynamic>? _retrievalAssignedSubscription;
  StreamSubscription<bool>? _webSocketConnectionSubscription;
  StreamSubscription<dynamic>? _retrievalCancelledSubscription;
  Timer? _pollingTimer;

  AssignedSessionsBackgroundBloc({this.webSocketBloc})
      : super(const AssignedSessionsBackgroundInitial()) {
    on<StartAssignedSessionsPolling>(_onStartPolling);
    on<StopAssignedSessionsPolling>(_onStopPolling);
    on<RefreshAssignedSessions>(_onRefreshAssignedSessions);
    on<ReinitializeWebSocket>(_onReinitializeWebSocket);
    on<_PollAssignedSessions>(_onPollSessions);
    on<SetSessionsFromPending>(_onSetSessionsFromPending);
    on<RetrievalCancelledReceived>(_onRetrievalCancelledReceived);
    on<SessionsReceivedFromSocket>(_onSessionsReceivedFromSocket);

    // Setup WebSocket listeners and connection monitoring
    _setupWebSocketConnectionMonitoring();

    // Fetch existing assigned sessions on startup
    _fetchExistingAssignedSessions();

    // Setup hot reload detection
    _setupHotReloadDetection();
  }

  void _setupHotReloadDetection() {
    // This will help detect if the app was hot reloaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (webSocketBloc != null && webSocketBloc!.isConnected) {
        _setupRetrievalAssignedListener();
      }
    });
  }

  /// Fetch existing assigned sessions when bloc starts
  void _fetchExistingAssignedSessions() {
    // Use addPostFrameCallback to ensure bloc is fully initialized
    Future.microtask(() {
      add(const _PollAssignedSessions());
    });
  }

  /// Monitor WebSocket connection and setup listeners when connected
  void _setupWebSocketConnectionMonitoring() {
    if (webSocketBloc == null) {
      print(
        'WebSocketBloc not provided to AssignedSessionsBackgroundBloc. '
        'No WebSocket functionality available.',
      );
      return;
    }

    // Listen to WebSocket connection status changes
    _webSocketConnectionSubscription =
        webSocketBloc!.service.connectionStream.listen((isConnected) {
      if (isConnected) {
        // WebSocket connected - setup the event listener
        _setupRetrievalAssignedListener();
        _setupRetrievalCancelledListener();
      } else {
        // WebSocket disconnected - cleanup the listener
        _cleanupRetrievalAssignedListener();
        _cleanupRetrievalCancelledListener();
      }
    });

    // If already connected, setup listener immediately
    if (webSocketBloc!.isConnected) {
      _setupRetrievalAssignedListener();
      _setupRetrievalCancelledListener();
    }
  }

  void _setupRetrievalCancelledListener() {
    _cleanupRetrievalCancelledListener();

    try {
      final retrievalCancelledStream =
          webSocketBloc!.service.getEventStream('retrieval:cancelled');

      _retrievalCancelledSubscription = retrievalCancelledStream.listen(
        (_) {
          add(const RetrievalCancelledReceived());
        },
        onError: (error) {
          print('Error listening to retrieval cancelled updates: $error');
        },
      );
    } catch (e) {
      print('Error setting up retrieval:cancelled listener: $e');
    }
  }

  void _cleanupRetrievalCancelledListener() {
    if (_retrievalCancelledSubscription != null) {
      _retrievalCancelledSubscription?.cancel();
      _retrievalCancelledSubscription = null;
    }
  }

  /// Setup the retrieval:assigned event listener
  void _setupRetrievalAssignedListener() {
    // Clean up any existing listener first
    _cleanupRetrievalAssignedListener();

    try {
      final retrievalAssignedStream =
          webSocketBloc!.service.getEventStream('retrieval:assigned');

      _retrievalAssignedSubscription = retrievalAssignedStream.listen(
        (data) {
          add(SessionsReceivedFromSocket(data));
        },
        onError: (error) {
          print('Error listening to retrieval assigned updates: $error');
        },
      );
    } catch (e) {
      print('Error setting up retrieval:assigned listener: $e');
    }
  }

  /// Cleanup the retrieval:assigned event listener
  void _cleanupRetrievalAssignedListener() {
    if (_retrievalAssignedSubscription != null) {
      _retrievalAssignedSubscription?.cancel();
      _retrievalAssignedSubscription = null;
    }
  }

  void _onStartPolling(
    StartAssignedSessionsPolling event,
    Emitter<AssignedSessionsBackgroundState> emit,
  ) {
    _pollingTimer?.cancel();
    // Background refresh every 5s: no loading state, non-blocking; UI stays responsive
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      add(const RefreshAssignedSessions());
    });
  }

  void _onStopPolling(
    StopAssignedSessionsPolling event,
    Emitter<AssignedSessionsBackgroundState> emit,
  ) {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _onRefreshAssignedSessions(
    RefreshAssignedSessions event,
    Emitter<AssignedSessionsBackgroundState> emit,
  ) {
    // Public method to manually refresh assigned sessions
    add(const _PollAssignedSessions());
  }

  void _onReinitializeWebSocket(
    ReinitializeWebSocket event,
    Emitter<AssignedSessionsBackgroundState> emit,
  ) {
    // Force cleanup and re-setup
    _cleanupRetrievalAssignedListener();
    _setupWebSocketConnectionMonitoring();

    // Force immediate refresh
    add(const _PollAssignedSessions());
  }

  void _onPollSessions(
    _PollAssignedSessions event,
    Emitter<AssignedSessionsBackgroundState> emit,
  ) async {
    try {
      final sessions = await AssignedSessionsApiService.fetchAssignedSessions();
      // Skip emit when display content is unchanged so bottom sheet image does not reload/flicker every 5s
      final current = state;
      if (current is AssignedSessionsBackgroundData &&
          _isSameDisplayContent(current.sessions, sessions)) {
        return;
      }
      emit(AssignedSessionsBackgroundData(sessions));
    } catch (e) {
      print('Failed to fetch assigned sessions: $e');
      // Intentionally no emit on error — background refresh stays silent
    }
  }

  /// Normalize photo URL to path (strip query) so signed/cache-busting URLs compare equal.
  static String _normalizePhotoUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    final q = url.indexOf('?');
    return q < 0 ? url : url.substring(0, q);
  }

  /// Stable key for the session shown in the retrieval bottom sheet (id + normalized photoUrl).
  static String _sessionDisplayKey(dynamic s) {
    if (s == null) return '';
    if (s is AssignedSession) {
      return '${s.id}|${_normalizePhotoUrl(s.photoUrl)}';
    }
    if (s is Map<String, dynamic>) {
      final id = (s['sessionId'] ?? s['id'])?.toString() ?? '';
      final photos = s['photos'];
      String? photoUrl;
      if (photos is List && photos.isNotEmpty) {
        final first = photos.first;
        if (first is Map<String, dynamic>) {
          photoUrl = first['url']?.toString();
        }
      }
      return '$id|${_normalizePhotoUrl(photoUrl)}';
    }
    return '';
  }

  static String? _sessionIdOfEntry(dynamic s) {
    if (s is AssignedSession) {
      return s.id.isNotEmpty ? s.id : null;
    }
    if (s is Map<String, dynamic>) {
      final id = (s['sessionId'] ?? s['id'])?.toString();
      return (id != null && id.isNotEmpty) ? id : null;
    }
    return null;
  }

  /// Ordered session ids so we emit when the queue changes (FIFO add/remove/reorder),
  /// not only when the first row's photo URL changes. Comparing [first] alone missed
  /// cases like [A]→[A,B,C] or [A,B,C]→[B,C] when A and B shared the same display key.
  static String _orderedSessionIdsSignature(List<dynamic> sessions) {
    return sessions.map((s) => _sessionIdOfEntry(s) ?? '').join('|');
  }

  /// Public for retrieval sheet [BlocBuilder.buildWhen] so the UI updates when the
  /// queue changes, not only when the first row's photo URL changes.
  static String orderedSessionIdsSignature(List<dynamic> sessions) {
    return _orderedSessionIdsSignature(sessions);
  }

  /// True if the list has the same display content so we avoid reloading the bottom sheet image.
  static bool _isSameDisplayContent(
      List<dynamic> current, List<dynamic> incoming) {
    if (current.length != incoming.length) return false;
    if (current.isEmpty) return true;
    if (_orderedSessionIdsSignature(current) !=
        _orderedSessionIdsSignature(incoming)) {
      return false;
    }
    return _sessionDisplayKey(current.first) ==
        _sessionDisplayKey(incoming.first);
  }

  /// Public so UI can use buildWhen: only rebuild when this changes (stops bottom sheet flicker).
  static String displayKeyOfFirstSession(List<dynamic> sessions) {
    if (sessions.isEmpty) return '';
    return _sessionDisplayKey(sessions.first);
  }

  /// Session id of the first assigned retrieval (for local-only Collect Keys gate).
  static String? sessionIdOfFirstSession(List<dynamic> sessions) {
    if (sessions.isEmpty) return null;
    final s = sessions.first;
    if (s is AssignedSession) {
      return s.id.isNotEmpty ? s.id : null;
    }
    if (s is Map<String, dynamic>) {
      final id = (s['sessionId'] ?? s['id'])?.toString();
      return (id != null && id.isNotEmpty) ? id : null;
    }
    return null;
  }

  void _onSetSessionsFromPending(
    SetSessionsFromPending event,
    Emitter<AssignedSessionsBackgroundState> emit,
  ) {
    if (event.sessions.isEmpty) return;
    emit(AssignedSessionsBackgroundData(
        sortAssignedSessionsFifoDynamic(event.sessions)));
  }

  void _onRetrievalCancelledReceived(
    RetrievalCancelledReceived event,
    Emitter<AssignedSessionsBackgroundState> emit,
  ) {
    emit(const AssignedSessionsCancelled());
  }

  void _onSessionsReceivedFromSocket(
    SessionsReceivedFromSocket event,
    Emitter<AssignedSessionsBackgroundState> emit,
  ) {
    try {
      final sessions = _extractSessions(event.data);
      if (sessions != null) {
        emit(AssignedSessionsBackgroundData(
            sortAssignedSessionsFifoDynamic(sessions)));
      }
    } catch (e) {
      print('Failed to parse WebSocket assigned sessions payload: $e');
    }
  }

  /// Best-effort extractor for assigned sessions from socket payloads
  List<dynamic>? _extractSessions(dynamic data) {
    if (data == null) return null;

    // If server sends { sessions: [...] }
    if (data is Map<String, dynamic> && data['sessions'] is List) {
      return List<dynamic>.from(data['sessions'] as List);
    }

    // If server sends a single session object
    if (data is Map<String, dynamic>) {
      return [data];
    }

    // If server sends a list directly
    if (data is List) {
      return List<dynamic>.from(data);
    }

    return null;
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    // Cancel WebSocket subscriptions
    _retrievalAssignedSubscription?.cancel();
    _retrievalCancelledSubscription?.cancel();
    _webSocketConnectionSubscription?.cancel();
    return super.close();
  }
}
