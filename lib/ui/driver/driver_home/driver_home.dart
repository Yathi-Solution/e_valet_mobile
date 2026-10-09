import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/bloc/driver/assigned_sessions_background/assigned_sessions_background_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_home/driver_menu_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_home/driver_menu_event.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_home/driver_menu_state.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_status/driver_status_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_status/driver_status_event.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_status/driver_status_state.dart';
import 'package:niloufer_valet_mobile/bloc/websocket/websocket_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/websocket/websocket_state.dart';
import 'package:niloufer_valet_mobile/api/driver/pre_break_info_api_service.dart';
import 'package:niloufer_valet_mobile/services/notification/firebase_messaging_service.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/guidelines/guidelines_screen.dart';
import 'package:niloufer_valet_mobile/ui/help_support/help_screen.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';
import 'package:niloufer_valet_mobile/ui/driver/confirm_arrival/confirm_arrival_screen.dart';
import 'package:niloufer_valet_mobile/ui/driver/confirm_arrival/confirm_arrival_flow_tracker.dart';
import 'package:niloufer_valet_mobile/ui/driver/driver_home/status/car_photo_intro_screen.dart';
import 'package:niloufer_valet_mobile/ui/driver/driver_home/driver_home_view.dart';
import 'package:niloufer_valet_mobile/ui/driver/driver_home/session_incomplete_dialog.dart';
import 'package:niloufer_valet_mobile/ui/driver/driver_home/widgets/pre_break_info_dialog.dart';
import 'package:niloufer_valet_mobile/ui/driver/retrival_request/assigned_session_sheet_loader.dart';
import 'package:niloufer_valet_mobile/ui/oauth/login/login.dart';
import 'package:niloufer_valet_mobile/ui/oauth/profile/profile_screen.dart';
import 'package:niloufer_valet_mobile/models/driver/session/assigned_session.dart';
import 'package:niloufer_valet_mobile/models/driver/session/pending_session.dart';
import 'package:niloufer_valet_mobile/models/driver/session/pending_sessions_response.dart';
import 'package:niloufer_valet_mobile/services/offline_sync/offline_parking_service.dart';
import 'package:niloufer_valet_mobile/utils/session_converter.dart';
import 'package:niloufer_valet_mobile/ui/driver/driver_home/park_flow_signals.dart';
import 'package:niloufer_valet_mobile/ui/driver/driver_home/driver_home_route_observer.dart';

/// True when every queued assignment id is in collect-keys-in-transit ack
/// (sheet should stay hidden until park completes or queue clears).
bool allQueuedSessionsInCollectKeysAck(List<dynamic> sessions) {
  if (sessions.isEmpty) return true;
  for (final s in sessions) {
    final id = AssignedSessionsBackgroundBloc.sessionIdOfFirstSession([s]);
    if (id == null || id.isEmpty) continue;
    if (!TokenStorage.collectKeysInTransitAckContainsSync(id)) return false;
  }
  return true;
}

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({
    super.key,
  });

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with WidgetsBindingObserver, RouteAware {
  static const Duration _pendingSessionsRefreshInterval = Duration(seconds: 2);

  /// When this changes, DriverHomeContent resets so home (two cards) is shown on reopen/return.
  final ValueNotifier<int> _homeResetNotifier = ValueNotifier(0);
  final DriverHomeRouteObserver _routeObserver = DriverHomeRouteObserver();
  Timer? _webSocketCheckTimer;
  Timer? _pendingSessionsRefreshTimer;
  StreamSubscription<void>? _retrievalNotificationTapSubscription;
  bool _refreshPendingFromNotification = false;
  bool _subscribedToRetrievalTap = false;

  /// When opening from retrieval push, assigned sessions may emit before
  /// [DriverMenuBloc] has loaded; we skip showing the sheet. Set this so we
  /// re-check when [DriverHomeLoaded] arrives.
  bool _pendingShowSheetWhenMenuLoaded = false;

  bool _isShowingAssignedSheet = false;
  BuildContext? _assignedSheetContext;

  // Store bloc references to avoid context issues in timer callbacks
  AssignedSessionsBackgroundBloc? _assignedBloc;
  WebSocketBloc? _webSocketBloc;

  /// [DriverMenuBloc] lives under [MultiBlocProvider] in [build]; [State.context] is above
  /// that subtree, so async callbacks must not use [State.context] for [context.read].
  BuildContext? _driverFlowContext;
  DriverMenuBloc? _driverMenuBloc;

  // Track if we've already shown the session incomplete dialog
  bool _hasShownSessionDialog = false;
  DateTime? _suppressSessionIncompleteDialogUntil;

  // Track if we've already navigated for accepted/arrived sessions
  bool _hasNavigatedForStatus = false;

  /// Last session id we auto-opened Confirm Arrival for (detect stuck guard if route observer misses didPopNext).
  String? _lastPushedConfirmArrivalSessionId;

  void _refreshPendingSessions() {
    try {
      final bloc = _driverMenuBloc;
      if (bloc != null && !bloc.isClosed) {
        bloc.add(const DriverPendingSessionsRefresh());
      }
    } catch (e) {
      // Ignore refresh errors when context is not ready
    }
  }

  void _refreshAssignedSessions() {
    try {
      final bloc = _assignedBloc;
      if (bloc != null && !bloc.isClosed) {
        bloc.add(const RefreshAssignedSessions());
      }
    } catch (_) {
      // Ignore refresh errors when bloc/context is not ready
    }
  }

  String _statusOfAssignedQueueEntry(dynamic session) {
    if (session is AssignedSession) {
      return session.retrievalLifecycleStatus;
    }
    if (session is Map<String, dynamic>) {
      final rawStatus = session['status'];
      if (rawStatus is String && rawStatus.trim().isNotEmpty) {
        return rawStatus.trim().toUpperCase();
      }
      if (rawStatus is Map<String, dynamic>) {
        for (final key in ['name', 'value', 'status', 'state', 'code']) {
          final value = rawStatus[key];
          if (value is String && value.trim().isNotEmpty) {
            return value.trim().toUpperCase();
          }
        }
      }
    }
    return '';
  }

  String? _firstAssignableRetrievalSessionId(List<dynamic> sessions) {
    for (final session in sessions) {
      final id =
          AssignedSessionsBackgroundBloc.sessionIdOfFirstSession([session]);
      if (id == null || id.isEmpty) continue;
      if (_statusOfAssignedQueueEntry(session) != 'ASSIGNED') continue;
      if (TokenStorage.collectKeysInTransitAckContainsSync(id)) continue;
      return id;
    }
    return null;
  }

  bool _isAssignedRetrievalPendingSession(PendingSession session) {
    final taskType = (session.taskType ?? '').trim().toUpperCase();
    final isRetrievalTask =
        taskType.contains('RETRIEVAL') || taskType.contains('RETRIEVE');
    if (!isRetrievalTask) return false;
    return session.status.trim().toUpperCase() == 'ASSIGNED';
  }

  List<AssignedSession> _assignedFallbackSessionsFromPending(
    PendingSessionsResponse pending,
  ) {
    final sessions = <AssignedSession>[];
    for (final pendingSession in pending.sessions) {
      if (!_isAssignedRetrievalPendingSession(pendingSession)) continue;
      sessions.add(SessionConverter.pendingToAssigned(pendingSession));
    }
    return sessions;
  }

  void _syncAssignedFromPendingFallback(
    BuildContext context,
    PendingSessionsResponse? pending,
  ) {
    if (pending == null) return;
    final assignedBloc = _assignedBloc;
    if (assignedBloc == null || assignedBloc.isClosed) return;

    final fallbackSessions = _assignedFallbackSessionsFromPending(pending);
    if (fallbackSessions.isEmpty) return;

    final state = assignedBloc.state;
    if (state is AssignedSessionsBackgroundData &&
        _firstAssignableRetrievalSessionId(state.sessions) != null) {
      return;
    }

    assignedBloc.add(SetSessionsFromPending(fallbackSessions));
  }

  void _startPendingSessionsRefreshTimer() {
    _pendingSessionsRefreshTimer?.cancel();
    _pendingSessionsRefreshTimer = Timer.periodic(
      _pendingSessionsRefreshInterval,
      (_) {
        if (!mounted) return;
        _refreshPendingSessions();
        _refreshAssignedSessions();
      },
    );
  }

  void _stopPendingSessionsRefreshTimer() {
    _pendingSessionsRefreshTimer?.cancel();
    _pendingSessionsRefreshTimer = null;
  }

  void _presentAssignedSessionSheet(BuildContext context) {
    _isShowingAssignedSheet = true;
    final assignedSessionsBloc = context.read<AssignedSessionsBackgroundBloc>();
    final driverMenuBloc = context.read<DriverMenuBloc>();
    final keepCurrentFlowOnAccept = ModalRoute.of(context)?.isCurrent != true;
    String? excludedSessionId;
    if (keepCurrentFlowOnAccept) {
      excludedSessionId = _lastPushedConfirmArrivalSessionId ??
          ConfirmArrivalFlowTracker.activeSessionId;
      if ((excludedSessionId == null || excludedSessionId.trim().isEmpty) &&
          ParkFlowSignals.isCarPhotoParkFlowActive) {
        excludedSessionId = TokenStorage.getSessionIdSync();
      }
    }

    showModalBottomSheet(
      context: context,
      // useRootNavigator: true makes the sheet attach to the root navigator so
      // it appears on top of ANY driver screen (CarPhotoIntroScreen, ConfirmArrivalScreen,
      // ProfileScreen, etc.), not only when DriverHomeScreen is the current route.
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      // Critical: this sheet must NOT close via outside tap, swipe/drag, or back.
      // It should close only when our backend/API state indicates no sessions.
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext modalContext) {
        _assignedSheetContext = modalContext;
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: assignedSessionsBloc),
            BlocProvider.value(value: driverMenuBloc),
          ],
          child: PopScope(
            canPop: false,
            child: AssignedSessionSheetLoader(
              keepCurrentFlowOnAccept: keepCurrentFlowOnAccept,
              excludedSessionId: excludedSessionId,
            ),
          ),
        );
      },
    ).then((_) {
      _assignedSheetContext = null;
      _isShowingAssignedSheet = false;
    });
  }

  void _closeAssignedSessionSheetIfOpen(BuildContext context) {
    if (!_isShowingAssignedSheet) return;
    final sheetContext = _assignedSheetContext;
    if (sheetContext != null && sheetContext.mounted) {
      final sheetNavigator = Navigator.of(sheetContext);
      if (sheetNavigator.canPop()) {
        sheetNavigator.pop();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _routeObserver.setOnRouteChanged(_onRouteChanged);

    // Location and camera are requested on PermissionsScreen before reaching this screen.

    // Start periodic WebSocket health check
    _startWebSocketHealthCheck();
    _startPendingSessionsRefreshTimer();
  }

  void _onRouteChanged() {
    // Route changes no longer need special handling: the retrieval sheet uses
    // useRootNavigator: true and therefore appears on top of any driver screen.
  }

  void _startWebSocketHealthCheck() {
    _webSocketCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _checkWebSocketHealth();
      }
    });
  }

  void _checkWebSocketHealth() {
    try {
      if (_assignedBloc == null || _webSocketBloc == null) return;
      if (_assignedBloc!.isClosed || _webSocketBloc!.isClosed) return;

      if (_webSocketBloc!.isConnected &&
          _assignedBloc!.state is AssignedSessionsBackgroundInitial) {
        if (!_assignedBloc!.isClosed) {
          _assignedBloc!.add(const RefreshAssignedSessions());
        }
      }
    } catch (e) {
      debugPrint('WebSocket health check error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _suppressSessionIncompleteDialogUntil =
          DateTime.now().add(const Duration(seconds: 8));
      OfflineParkingService.syncPendingData();
      // App came back to foreground - preserve current screen (do not reset to home).
      // User stays on QR/park flow unless they press back.
      _checkWebSocketOnResume();
      _hasNavigatedForStatus = false;
      _lastPushedConfirmArrivalSessionId = null;
      _refreshPendingSessions();
      try {
        if (_assignedBloc != null && !_assignedBloc!.isClosed) {
          _assignedBloc!.add(const RefreshAssignedSessions());
        }
      } catch (_) {}
      _startPendingSessionsRefreshTimer();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _stopPendingSessionsRefreshTimer();
    }
  }

  bool _shouldSuppressSessionIncompleteDialogForSession(String sessionId) {
    final suppressUntil = _suppressSessionIncompleteDialogUntil;
    if (suppressUntil != null && DateTime.now().isBefore(suppressUntil)) {
      return true;
    }
    if (OfflineParkingService.hasPendingSyncForSession(sessionId)) {
      return true;
    }
    return false;
  }

  @override
  void didUpdateWidget(covariant DriverHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Builder widget in build() will handle refresh on widget update
  }

  void _checkWebSocketOnResume() {
    // The Builder widget in build() will handle the refresh when app resumes
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _webSocketBloc ??= context.read<WebSocketBloc>();

    // Subscribe to route changes
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      _routeObserver.subscribe(this, route);
    }

    // When app is opened from retrieval push notification, refresh pending/session API
    if (!_subscribedToRetrievalTap) {
      try {
        final fcm =
            Provider.of<FirebaseMessagingService>(context, listen: false);
        _retrievalNotificationTapSubscription =
            fcm.onRetrievalNotificationTap.listen((_) {
          if (mounted) {
            setState(() => _refreshPendingFromNotification = true);
          }
        });
        _subscribedToRetrievalTap = true;
      } catch (e, stackTrace) {
        debugPrint('Failed to subscribe to retrieval notification taps: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  @override
  void didPopNext() {
    super.didPopNext();
    // When user returns to driver home (e.g. from Car Camera or Confirm Arrival), reset so home (two cards) is shown, not Vehicle details.
    _homeResetNotifier.value++;
    // Reset so we can navigate to Confirm Arrival again if operator changed status while we were away
    _hasNavigatedForStatus = false;
    _lastPushedConfirmArrivalSessionId = null;
    _refreshPendingSessions();
    // Refetch assigned-to-me immediately so the next retrieval in the queue surfaces
    // (polling alone can leave stale state for up to 5s; another park looked like the "fix").
    try {
      if (_assignedBloc != null && !_assignedBloc!.isClosed) {
        _assignedBloc!.add(const RefreshAssignedSessions());
      }
    } catch (_) {}
    // Pending/assigned refresh is async; re-run full driver-flow resolution so the
    // next deferred Confirm Arrival opens even if DriverMenuBloc did not emit again.
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      final ctx = _driverFlowContext;
      if (ctx == null || !ctx.mounted) return;
      _tryResumeDriverFlowFromHome(ctx);
    });
  }

  @override
  void didPush() {
    super.didPush();
  }

  @override
  void dispose() {
    _webSocketCheckTimer?.cancel();
    _stopPendingSessionsRefreshTimer();
    _retrievalNotificationTapSubscription?.cancel();
    _routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _assignedBloc = null;
    _webSocketBloc = null;
    _driverFlowContext = null;
    _driverMenuBloc = null;
    _assignedSheetContext = null;
    _hasShownSessionDialog = false;
    _hasNavigatedForStatus = false;
    _lastPushedConfirmArrivalSessionId = null;
    _pendingShowSheetWhenMenuLoaded = false;
    _isShowingAssignedSheet = false;
    super.dispose();
  }

  /// Deferred Collect Keys: block auto Confirm Arrival only while park flow is active.
  bool _canResumeDeferredRetrievalConfirm(
    BuildContext context,
    String sessionId,
  ) {
    try {
      if (ParkFlowSignals.isCarPhotoParkFlowActive) return false;
    } catch (_) {}
    try {
      final route = ModalRoute.of(context);
      if (route?.isCurrent != true) return false;
    } catch (_) {}
    try {
      final hivePark = TokenStorage.getSessionIdSync();
      if (hivePark != null &&
          hivePark.isNotEmpty &&
          hivePark.trim() == sessionId.trim()) {
        return false;
      }
    } catch (_) {}
    try {
      final menu = context.read<DriverMenuBloc>().state;
      if (menu is DriverHomeLoaded && menu.pendingSessions != null) {
        final p = menu.pendingSessions!;
        final rep = p.reparkingSession;
        if (rep != null && rep.sessionId.trim() == sessionId.trim()) {
          return false;
        }
        final chk = p.checkedInSession;
        if (chk != null && chk.sessionId.trim() == sessionId.trim()) {
          return false;
        }
      }
    } catch (_) {}
    return true;
  }

  bool _pendingSessionNeedsConfirmArrivalNavigation(
    BuildContext context,
    PendingSession s,
  ) {
    if (TokenStorage.shouldSuppressAutoConfirmArrivalForSessionSync(
        s.sessionId)) {
      return false;
    }
    if (!TokenStorage.collectKeysInTransitAckContainsSync(s.sessionId)) {
      return true;
    }
    return _canResumeDeferredRetrievalConfirm(context, s.sessionId);
  }

  /// Same session id as assigned retrieval still needs Confirm Arrival (including deferred after park).
  bool _pendingNeedsConfirmForAssignedRetrieval(
    BuildContext context,
    PendingSessionsResponse? pending,
    String assignedRetrievalSessionId,
  ) {
    if (pending == null) return false;
    final aid = assignedRetrievalSessionId.trim();
    if (aid.isEmpty) return false;
    for (final s in pending.sessions) {
      if (s.sessionId.trim() != aid) continue;
      if (s.isArrived &&
          _pendingSessionNeedsConfirmArrivalNavigation(context, s)) {
        return true;
      }
      if (s.isAccepted &&
          _pendingSessionNeedsConfirmArrivalNavigation(context, s)) {
        return true;
      }
    }
    return false;
  }

  DateTime? _pendingSessionFifoTime(PendingSession session) {
    final assignedAtRaw = (session.assignedAt ?? '').trim();
    if (assignedAtRaw.isNotEmpty) {
      final assignedAt = DateTime.tryParse(assignedAtRaw);
      if (assignedAt != null) return assignedAt;
    }
    final createdAtRaw = session.createdAt.trim();
    if (createdAtRaw.isNotEmpty) {
      return DateTime.tryParse(createdAtRaw);
    }
    return null;
  }

  int _comparePendingSessionsFifo(PendingSession a, PendingSession b) {
    final ta = _pendingSessionFifoTime(a);
    final tb = _pendingSessionFifoTime(b);
    if (ta == null && tb == null) {
      return a.sessionId.compareTo(b.sessionId);
    }
    if (ta == null) return 1;
    if (tb == null) return -1;
    final c = ta.compareTo(tb);
    if (c != 0) return c;
    return a.sessionId.compareTo(b.sessionId);
  }

  /// Driver-flow target selection:
  /// 1) keep first API item if it is a parking continuation task
  /// 2) otherwise resume retrieval Confirm Arrival in FIFO order (oldest first)
  /// 3) fallback to first API item
  PendingSession? _nextPendingSessionForDriverFlow(
    BuildContext context,
    PendingSessionsResponse pending,
  ) {
    if (pending.sessions.isEmpty) return null;
    final top = pending.sessions.first;
    if (top.isReparking || top.isCheckedIn) {
      return top;
    }

    final retrievalCandidates = pending.sessions
        .where((s) => s.isArrived || s.isAccepted)
        .toList()
      ..sort(_comparePendingSessionsFifo);
    if (retrievalCandidates.isNotEmpty) {
      // Strict FIFO: always keep the oldest accepted/arrived retrieval as head.
      // Do not advance to newer retrievals while this head is pending/suppressed.
      return retrievalCandidates.first;
    }

    return top;
  }

  bool _shouldDeferRetrievalSheetForTopPendingTask(
    BuildContext context,
    PendingSessionsResponse? pending,
    String assignedRetrievalSessionId,
  ) {
    if (pending == null || pending.sessions.isEmpty) return false;
    final assignedId = assignedRetrievalSessionId.trim();
    if (assignedId.isEmpty) return false;
    final nextPending = _nextPendingSessionForDriverFlow(context, pending);
    if (nextPending == null) return false;
    if (nextPending.sessionId.trim() != assignedId) return false;
    if (nextPending.isReparking || nextPending.isCheckedIn) return true;
    if (nextPending.isArrived || nextPending.isAccepted) {
      return true;
    }
    return false;
  }

  AssignedSession? _findAssignedSessionById(List<dynamic> sessions, String id) {
    final aid = id.trim();
    if (aid.isEmpty) return null;
    for (final s in sessions) {
      if (s is AssignedSession) {
        if (s.id.trim() == aid) return s;
      } else if (s is Map<String, dynamic>) {
        final raw = (s['sessionId'] ?? s['id'])?.toString().trim();
        if (raw == aid) {
          try {
            return AssignedSession.fromJson(s);
          } catch (_) {}
        }
      }
    }
    return null;
  }

  /// When pending API lags, next deferred id may still appear on assigned-to-me only.
  AssignedSession? _firstAssignedDeferredNeedingConfirm(BuildContext context) {
    final defOrder = TokenStorage.collectKeysInTransitOrderedIdsSync();
    if (defOrder.isEmpty) return null;
    final assignedState = context.read<AssignedSessionsBackgroundBloc>().state;
    if (assignedState is! AssignedSessionsBackgroundData ||
        !assignedState.hasSessions) {
      return null;
    }
    for (final id in defOrder) {
      if (TokenStorage.shouldSuppressAutoConfirmArrivalForSessionSync(id)) {
        continue;
      }
      final s = _findAssignedSessionById(assignedState.sessions, id);
      if (s == null) continue;
      final st = s.retrievalLifecycleStatus;
      if (st == 'ARRIVED' && _canResumeDeferredRetrievalConfirm(context, id)) {
        return s;
      }
    }
    for (final id in defOrder) {
      if (TokenStorage.shouldSuppressAutoConfirmArrivalForSessionSync(id)) {
        continue;
      }
      final s = _findAssignedSessionById(assignedState.sessions, id);
      if (s == null) continue;
      final st = s.retrievalLifecycleStatus;
      if (st == 'ACCEPTED' && _canResumeDeferredRetrievalConfirm(context, id)) {
        return s;
      }
    }
    return null;
  }

  /// Repark / checked-in / Confirm Arrival / retrieval sheet — single place so
  /// [didPopNext] can re-run the same logic after a route pop (listener alone may not fire).
  void _tryResumeDriverFlowFromHome(BuildContext context) {
    if (!mounted) return;
    // Avoid resolving/closing flows while another driver route (e.g. Confirm Arrival,
    // Handover, camera) is on top. Running this underneath can close a newly shown
    // retrieval sheet within 1-2s and make it appear to "flash" then disappear.
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final menuState = context.read<DriverMenuBloc>().state;
    if (menuState is! DriverHomeLoaded) return;

    if (_pendingShowSheetWhenMenuLoaded && mounted) {
      _pendingShowSheetWhenMenuLoaded = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _attemptShowAssignedSessionSheet(context);
      });
    }

    var scheduledDriverFlowNavigation = false;

    final pending = menuState.pendingSessions;
    PendingSession? nextPendingForFlow;
    if (pending != null) {
      nextPendingForFlow = _nextPendingSessionForDriverFlow(
        context,
        pending,
      );
      // If the next pending row is a different session than what we last opened,
      // clear the stuck guard (RouteAware.didPopNext only runs when this observer
      // is on MaterialApp.navigatorObservers).
      if (_hasNavigatedForStatus &&
          nextPendingForFlow != null &&
          nextPendingForFlow.sessionId.trim() !=
              (_lastPushedConfirmArrivalSessionId ?? '').trim()) {
        _hasNavigatedForStatus = false;
      }
    }

    if (!scheduledDriverFlowNavigation && !_hasNavigatedForStatus) {
      PendingSession? target;
      AssignedSession? assignedOnlyTarget;

      if (pending != null) {
        target = nextPendingForFlow;
      } else {
        assignedOnlyTarget = _firstAssignedDeferredNeedingConfirm(context);
      }

      if (target != null) {
        if (target.isReparking) {
          scheduledDriverFlowNavigation = true;
          _hasNavigatedForStatus = true;
          _closeAssignedSessionSheetIfOpen(context);
          final reparkingSession = target;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && ModalRoute.of(context)?.isCurrent == true) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CarPhotoIntroScreen(
                    cameViaTagNumber: false,
                    sessionId: reparkingSession.sessionId,
                    isReparking: true,
                    cardNumber: reparkingSession.cardNumber.toString(),
                  ),
                ),
              );
            }
          });
        } else if (target.isCheckedIn) {
          if (_shouldSuppressSessionIncompleteDialogForSession(
              target.sessionId)) {
            return;
          }
          // Keep first API task in focus; do not jump to retrieval while this is first.
          scheduledDriverFlowNavigation = true;
          _hasNavigatedForStatus = true;
          _closeAssignedSessionSheetIfOpen(context);
          if (!_hasShownSessionDialog) {
            _hasShownSessionDialog = true;
            final checkedInSession = target;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && ModalRoute.of(context)?.isCurrent == true) {
                SessionIncompleteDialog.show(
                  context,
                  cardNumber: checkedInSession.cardNumber.toString(),
                  onContinue: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CarPhotoIntroScreen(
                          cameViaTagNumber: false,
                          sessionId: checkedInSession.sessionId,
                          cardNumber: checkedInSession.cardNumber.toString(),
                        ),
                      ),
                    );
                  },
                );
              }
            });
          }
        } else if ((target.isArrived || target.isAccepted) &&
            _pendingSessionNeedsConfirmArrivalNavigation(context, target)) {
          scheduledDriverFlowNavigation = true;
          _closeAssignedSessionSheetIfOpen(context);
          final pendingTarget = target;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final routeIsCurrent = ModalRoute.of(context)?.isCurrent == true;
            if (!routeIsCurrent) return;
            if (!mounted) return;
            _hasNavigatedForStatus = true;
            _lastPushedConfirmArrivalSessionId = pendingTarget.sessionId.trim();
            final assignedSession =
                SessionConverter.pendingToAssigned(pendingTarget);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ConfirmArrivalScreen(
                  session: assignedSession,
                  preventBackNavigation: true,
                  showHandoverOnLoad: pendingTarget.isArrived,
                ),
              ),
            );
          });
        } else {
          // Top API row is not actionable for confirm-arrival navigation
          // (e.g. transient stale status); avoid reopening stale retrieval UI.
        }
      } else if (assignedOnlyTarget != null) {
        scheduledDriverFlowNavigation = true;
        _closeAssignedSessionSheetIfOpen(context);
        final sessionToOpen = assignedOnlyTarget;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final routeIsCurrent = ModalRoute.of(context)?.isCurrent == true;
          if (!routeIsCurrent) return;
          if (!mounted) return;
          _hasNavigatedForStatus = true;
          _lastPushedConfirmArrivalSessionId = sessionToOpen.id.trim();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ConfirmArrivalScreen(
                session: sessionToOpen,
                preventBackNavigation: true,
                showHandoverOnLoad:
                    sessionToOpen.retrievalLifecycleStatus == 'ARRIVED',
              ),
            ),
          );
        });
      }
    }

    if (!scheduledDriverFlowNavigation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _attemptShowAssignedSessionSheet(context);
      });
    }
  }

  void _attemptShowAssignedSessionSheet(BuildContext blocContext) {
    if (!mounted || _isShowingAssignedSheet) return;

    // No isCurrent check needed: the sheet uses useRootNavigator: true, so it
    // appears on top of any driver screen (not just the home screen).

    final assignedState =
        blocContext.read<AssignedSessionsBackgroundBloc>().state;
    if (assignedState is! AssignedSessionsBackgroundData ||
        !assignedState.hasSessions) {
      return;
    }

    if (allQueuedSessionsInCollectKeysAck(assignedState.sessions)) {
      return;
    }

    final firstId = _firstAssignableRetrievalSessionId(assignedState.sessions);
    if (firstId == null || firstId.isEmpty) {
      return;
    }
    if (TokenStorage.shouldSuppressAutoConfirmArrivalForSessionSync(firstId)) {
      return;
    }

    final driverMenuState = blocContext.read<DriverMenuBloc>().state;
    if (driverMenuState is! DriverHomeLoaded) {
      _pendingShowSheetWhenMenuLoaded = true;
      return;
    }

    final pendingSessions = driverMenuState.pendingSessions;
    // If top pending task should be resumed directly (parking or confirm-arrival),
    // don't flash retrieval sheet for 1-2s during refresh races on home.
    // Keep showing the sheet on non-home routes (Confirm Arrival/Handover) so
    // collect-keys in-transit behavior continues to work.
    final isHomeCurrent = ModalRoute.of(blocContext)?.isCurrent == true;
    if (isHomeCurrent &&
        _shouldDeferRetrievalSheetForTopPendingTask(
            blocContext, pendingSessions, firstId)) {
      return;
    }

    // Reparking: only block retrieval for the **same** session as this assignment.
    // Otherwise a different REPARKING row was hiding the sheet on camera/preview.
    if (pendingSessions != null && pendingSessions.hasReparkingSession) {
      final rep = pendingSessions.reparkingSession;
      if (rep != null && rep.sessionId.trim() == firstId.trim()) {
        return;
      }
    }

    // Block retrieval sheet only when **this** assigned retrieval session still
    // needs Confirm Arrival. Another session’s ACCEPTED/ARRIVED must not hide
    // a new assignment while you’re on another screen.
    if (_pendingNeedsConfirmForAssignedRetrieval(
        blocContext, pendingSessions, firstId)) {
      return;
    }

    _pendingShowSheetWhenMenuLoaded = false;
    _presentAssignedSessionSheet(blocContext);
  }

  Widget _buildActionBlockingLoader() {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: AppColors.black.withOpacity(0.45),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (context) => AssignedSessionsBackgroundBloc(
                  webSocketBloc: context.read<WebSocketBloc>(),
                )),
        BlocProvider(
            create: (_) =>
                DriverStatusBloc()..add(const DriverStatusStarted())),
      ],
      child: Builder(
        builder: (context) {
          // Now we can safely access the blocs since we're inside the MultiBlocProvider
          _driverFlowContext = context;
          _driverMenuBloc = context.read<DriverMenuBloc>();
          try {
            final assignedBloc = context.read<AssignedSessionsBackgroundBloc>();
            // Store the bloc reference for use in timer callbacks
            _assignedBloc = assignedBloc;

            // When opened from retrieval notification tap, refresh session/pending API first
            if (_refreshPendingFromNotification) {
              _refreshPendingFromNotification = false;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _refreshPendingSessions();
                assignedBloc.add(const RefreshAssignedSessions());
              });
            } else {
              // Force immediate refresh on every build when not triggered by notification
              assignedBloc.add(const RefreshAssignedSessions());
            }
            // WebSocket listeners are automatically set up in bloc constructor
          } catch (e) {
            _assignedBloc = null;
          }

          return MultiBlocListener(
            listeners: [
              BlocListener<AssignedSessionsBackgroundBloc,
                  AssignedSessionsBackgroundState>(
                listener: (blocContext, state) {
                  // Only "data available" means AssignedSessionsBackgroundData with sessions
                  final hasData = state is AssignedSessionsBackgroundData &&
                      state.hasSessions;
                  // No data (empty, initial, or cancelled) → close sheet; never show empty sheet
                  if (!hasData) {
                    _closeAssignedSessionSheetIfOpen(blocContext);
                    TokenStorage.clearCollectKeysInTransitAckSync();
                    return;
                  }
                  // Data available → attempt to show sheet on any driver screen.
                  // The sheet uses useRootNavigator: true, so it appears on top of
                  // whatever driver screen is currently active.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _attemptShowAssignedSessionSheet(blocContext);
                  });
                },
              ),
              // Add WebSocket connection monitoring
              BlocListener<WebSocketBloc, WebSocketState>(
                listener: (context, state) {
                  // WebSocket state monitoring (no debug prints needed)
                },
              ),
              BlocListener<DriverMenuBloc, DriverMenuState>(
                listener: (context, state) {
                  if (state is DriverMenuLogoutSuccess) {
                    // Show success message
                    SnackBars.showSuccessSnackBar(
                        context, state.response.message);
                    // Navigate to login screen
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                    // Reset state
                    context.read<DriverMenuBloc>().add(const DriverMenuReset());
                  } else if (state is DriverMenuLogoutFailure) {
                    // Show error message
                    SnackBars.showErrorSnackBar(context, state.message);
                    // Still navigate to login screen even on failure (tokens are cleared locally)
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                    // Reset state
                    context.read<DriverMenuBloc>().add(const DriverMenuReset());
                  } else if (state is DriverMenuLogoutBlockedByPendingWork) {
                    PreBreakInfoDialog.show(
                      context,
                      title: 'Cannot Logout',
                      actionLabel: 'logout',
                      info: state.preBreakInfo,
                    ).then((selectedDriver) async {
                      if (!context.mounted) return;
                      if (selectedDriver == null) {
                        context
                            .read<DriverMenuBloc>()
                            .add(const DriverMenuReset());
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const DriverHomeScreen(),
                          ),
                          (route) => false,
                        );
                        return;
                      }
                      // After passing sessions, re-check pending work before retrying logout.
                      // This avoids a confusing "popup loop" when other blockers (active retrievals /
                      // pending assignments) still exist.
                      try {
                        final latest =
                            await PreBreakInfoApiService.getPreBreakInfo();
                        if (!context.mounted) return;
                        if (latest.hasBlockingData) {
                          SnackBars.showErrorSnackBar(
                            context,
                            'Logout is still blocked. Please finish active retrievals / pending assignments first.',
                          );
                          PreBreakInfoDialog.show(
                            context,
                            title: 'Cannot Logout',
                            actionLabel: 'logout',
                            info: latest,
                          );
                          return;
                        }
                      } catch (e) {
                        // If we fail to re-check, fall back to previous behavior.
                        print(
                            '🟢 LOGOUT FLOW recheck failed, retrying logout anyway: $e');
                      }

                      context
                          .read<DriverMenuBloc>()
                          .add(const DriverLogoutPressed());
                    });
                  } else if (state is DriverMenuAction) {
                    switch (state.action) {
                      case DriverMenuActionType.profile:
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                        // Reset state so the same action can be handled again later
                        context
                            .read<DriverMenuBloc>()
                            .add(const DriverMenuReset());
                        break;
                      case DriverMenuActionType.guidelines:
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const GuidelinesScreen(),
                          ),
                        );
                        context
                            .read<DriverMenuBloc>()
                            .add(const DriverMenuReset());
                        break;
                      case DriverMenuActionType.help:
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HelpScreen(),
                          ),
                        );
                        context
                            .read<DriverMenuBloc>()
                            .add(const DriverMenuReset());
                        break;
                      case DriverMenuActionType.logout:
                        // This case is now handled by DriverMenuLogoutSuccess/Failure
                        break;
                    }
                  } else if (state is DriverHomeLoaded) {
                    _syncAssignedFromPendingFallback(
                      context,
                      state.pendingSessions,
                    );
                    _tryResumeDriverFlowFromHome(context);
                  }
                },
              ),
              BlocListener<DriverStatusBloc, DriverStatusState>(
                listener: (context, state) {
                  if (state is DriverBreakStartSuccess) {
                    SnackBars.showSuccessSnackBar(context, state.message);
                  } else if (state is DriverBreakEndSuccess) {
                    SnackBars.showSuccessSnackBar(context, state.message);
                  } else if (state is DriverBreakBlockedByPendingWork) {
                    PreBreakInfoDialog.show(
                      context,
                      title: 'Cannot Start Break',
                      actionLabel: 'start break',
                      info: state.preBreakInfo,
                    ).then((selectedDriver) {
                      if (!context.mounted || selectedDriver == null) return;
                      context
                          .read<DriverStatusBloc>()
                          .add(const DriverBreakToggled(true));
                    });
                  } else if (state is DriverStatusError) {
                    SnackBars.showErrorSnackBar(context, state.message);
                  }
                },
              ),
            ],
            child: BlocBuilder<DriverMenuBloc, DriverMenuState>(
              builder: (context, menuState) {
                return BlocBuilder<DriverStatusBloc, DriverStatusState>(
                  builder: (context, statusState) {
                    final isLogoutActionInProgress =
                        menuState is DriverMenuLogoutPrecheckLoading ||
                            menuState is DriverMenuLogoutLoading;
                    final isBreakActionInProgress =
                        statusState is DriverBreakToggleLoading;
                    final shouldBlockActions =
                        isLogoutActionInProgress || isBreakActionInProgress;

                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            try {
                              final assignedBloc = context
                                  .read<AssignedSessionsBackgroundBloc>();
                              assignedBloc.add(const RefreshAssignedSessions());
                            } catch (e) {
                              print('Manual WebSocket refresh failed: $e');
                            }
                          },
                          child: DriverHomeView(
                            homeResetNotifier: _homeResetNotifier,
                          ),
                        ),
                        if (shouldBlockActions) _buildActionBlockingLoader(),
                      ],
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
