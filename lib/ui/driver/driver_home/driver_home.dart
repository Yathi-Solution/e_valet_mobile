import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:evalet/bloc/driver/assigned_sessions_background/assigned_sessions_background_bloc.dart';
import 'package:evalet/bloc/driver/driver_home/driver_menu_bloc.dart';
import 'package:evalet/bloc/driver/driver_home/driver_menu_event.dart';
import 'package:evalet/bloc/driver/driver_home/driver_menu_state.dart';
import 'package:evalet/bloc/driver/driver_status/driver_status_bloc.dart';
import 'package:evalet/bloc/driver/driver_status/driver_status_event.dart';
import 'package:evalet/bloc/driver/driver_status/driver_status_state.dart';
import 'package:evalet/bloc/websocket/websocket_bloc.dart';
import 'package:evalet/api/driver/pre_break_info_api_service.dart';
import 'package:evalet/services/notification/firebase_messaging_service.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/guidelines/guidelines_screen.dart';
import 'package:evalet/ui/help_support/help_screen.dart';
import 'package:evalet/ui/common/widgets/snack_bar.dart';
import 'package:evalet/ui/driver/confirm_arrival/confirm_arrival_screen.dart';
import 'package:evalet/ui/driver/confirm_arrival/confirm_arrival_flow_tracker.dart';
import 'package:evalet/ui/driver/driver_home/status/car_photo_intro_screen.dart';
import 'package:evalet/ui/driver/driver_home/driver_home_view.dart';
import 'package:evalet/ui/driver/driver_home/session_incomplete_dialog.dart';
import 'package:evalet/ui/driver/driver_home/widgets/pre_break_info_dialog.dart';
import 'package:evalet/ui/driver/retrival_request/assigned_session_sheet_loader.dart';
import 'package:evalet/ui/oauth/login/login.dart';
import 'package:evalet/ui/oauth/profile/profile_screen.dart';
import 'package:evalet/models/driver/session/assigned_session.dart';
import 'package:evalet/models/driver/session/pending_session.dart';
import 'package:evalet/models/driver/session/pending_sessions_response.dart';
import 'package:evalet/services/offline_sync/offline_parking_service.dart';
import 'package:evalet/ui/driver/driver_home/park_flow_signals.dart';
import 'package:evalet/ui/driver/driver_home/driver_home_route_observer.dart';
import 'package:evalet/ui/driver/driver_home/driver_flow_resolver.dart';
import 'package:evalet/ui/driver/driver_home/widgets/action_blocking_loader.dart';

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

  /// The rules for what to open next; this widget only carries them out.
  static const DriverFlowResolver _flow = DriverFlowResolver();

  /// True when the driver home is the top route. Treated as true if the route
  /// cannot be read, so a lookup failure never blocks the flow.
  bool _homeIsCurrent(BuildContext context) {
    try {
      return ModalRoute.of(context)?.isCurrent == true;
    } catch (_) {
      return true;
    }
  }

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

  void _syncAssignedFromPendingFallback(PendingSessionsResponse? pending) {
    final assignedBloc = _assignedBloc;
    if (assignedBloc == null || assignedBloc.isClosed) return;

    final sessions = _flow.assignedSessionsToAdoptFromPending(
      pending,
      assignedBloc.state,
    );
    if (sessions == null) return;
    assignedBloc.add(SetSessionsFromPending(sessions));
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

    final pending = menuState.pendingSessions;
    final nextPending =
        pending == null ? null : _flow.nextPendingSessionForDriverFlow(pending);
    // If the next pending row is a different session than what we last opened,
    // clear the stuck guard (RouteAware.didPopNext only runs when this observer
    // is on MaterialApp.navigatorObservers).
    if (_hasNavigatedForStatus &&
        nextPending != null &&
        nextPending.sessionId.trim() !=
            (_lastPushedConfirmArrivalSessionId ?? '').trim()) {
      _hasNavigatedForStatus = false;
    }

    final DriverFlowStep step = _hasNavigatedForStatus
        ? const DriverFlowNone()
        : _flow.resolveNextStep(
            pending: pending,
            nextPending: nextPending,
            assignedState: context.read<AssignedSessionsBackgroundBloc>().state,
            isSessionIncompleteSuppressed:
                _shouldSuppressSessionIncompleteDialogForSession,
          );

    switch (step) {
      case DriverFlowHold():
        return;
      case DriverFlowNone():
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _attemptShowAssignedSessionSheet(context);
        });
      case DriverFlowRepark(:final session):
        _hasNavigatedForStatus = true;
        _closeAssignedSessionSheetIfOpen(context);
        _openReparkAfterFrame(context, session);
      case DriverFlowSessionIncomplete(:final session):
        // Keep first API task in focus; do not jump to retrieval while this is first.
        _hasNavigatedForStatus = true;
        _closeAssignedSessionSheetIfOpen(context);
        if (!_hasShownSessionDialog) {
          _hasShownSessionDialog = true;
          _showSessionIncompleteAfterFrame(context, session);
        }
      case DriverFlowConfirmArrival(:final session, :final isArrived):
        _closeAssignedSessionSheetIfOpen(context);
        _openConfirmArrivalAfterFrame(context, session, isArrived: isArrived);
    }
  }

  void _openReparkAfterFrame(BuildContext context, PendingSession session) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CarPhotoIntroScreen(
              cameViaTagNumber: false,
              sessionId: session.sessionId,
              isReparking: true,
              cardNumber: session.cardNumber.toString(),
            ),
          ),
        );
      }
    });
  }

  void _showSessionIncompleteAfterFrame(
    BuildContext context,
    PendingSession session,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        SessionIncompleteDialog.show(
          context,
          cardNumber: session.cardNumber.toString(),
          onContinue: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CarPhotoIntroScreen(
                  cameViaTagNumber: false,
                  sessionId: session.sessionId,
                  cardNumber: session.cardNumber.toString(),
                ),
              ),
            );
          },
        );
      }
    });
  }

  void _openConfirmArrivalAfterFrame(
    BuildContext context,
    AssignedSession session, {
    required bool isArrived,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ModalRoute.of(context)?.isCurrent != true) return;
      _hasNavigatedForStatus = true;
      _lastPushedConfirmArrivalSessionId = session.id.trim();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConfirmArrivalScreen(
            session: session,
            preventBackNavigation: true,
            showHandoverOnLoad: isArrived,
          ),
        ),
      );
    });
  }

  void _attemptShowAssignedSessionSheet(BuildContext blocContext) {
    if (!mounted || _isShowingAssignedSheet) return;

    // The sheet uses useRootNavigator: true, so it can appear on top of any
    // driver screen (not just the home screen).
    final menuState = blocContext.read<DriverMenuBloc>().state;
    final decision = _flow.decideRetrievalSheet(
      assignedState: blocContext.read<AssignedSessionsBackgroundBloc>().state,
      menuLoaded: menuState is DriverHomeLoaded,
      pending: menuState is DriverHomeLoaded ? menuState.pendingSessions : null,
      homeIsCurrent: _homeIsCurrent(blocContext),
    );

    switch (decision) {
      case RetrievalSheetDecision.skip:
        return;
      case RetrievalSheetDecision.waitForMenu:
        _pendingShowSheetWhenMenuLoaded = true;
      case RetrievalSheetDecision.show:
        _pendingShowSheetWhenMenuLoaded = false;
        _presentAssignedSessionSheet(blocContext);
    }
  }

  void _onAssignedSessionsState(
    BuildContext blocContext,
    AssignedSessionsBackgroundState state,
  ) {
    // Only "data available" means AssignedSessionsBackgroundData with sessions
    final hasData =
        state is AssignedSessionsBackgroundData && state.hasSessions;
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
  }

  void _onDriverMenuState(BuildContext context, DriverMenuState state) {
    if (state is DriverMenuLogoutSuccess) {
      SnackBars.showSuccessSnackBar(context, state.response.message);
      _goToLoginAfterLogout(context);
    } else if (state is DriverMenuLogoutFailure) {
      SnackBars.showErrorSnackBar(context, state.message);
      // Still navigate to login screen even on failure (tokens are cleared locally)
      _goToLoginAfterLogout(context);
    } else if (state is DriverMenuLogoutBlockedByPendingWork) {
      _onLogoutBlockedByPendingWork(context, state);
    } else if (state is DriverMenuAction) {
      _onDriverMenuAction(context, state.action);
    } else if (state is DriverHomeLoaded) {
      _syncAssignedFromPendingFallback(state.pendingSessions);
      _tryResumeDriverFlowFromHome(context);
    }
  }

  void _goToLoginAfterLogout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
    // Reset state
    context.read<DriverMenuBloc>().add(const DriverMenuReset());
  }

  void _onLogoutBlockedByPendingWork(
    BuildContext context,
    DriverMenuLogoutBlockedByPendingWork state,
  ) {
    PreBreakInfoDialog.show(
      context,
      title: 'Cannot Logout',
      actionLabel: 'logout',
      info: state.preBreakInfo,
    ).then((selectedDriver) async {
      if (!context.mounted) return;
      if (selectedDriver == null) {
        context.read<DriverMenuBloc>().add(const DriverMenuReset());
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
        final latest = await PreBreakInfoApiService.getPreBreakInfo();
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
        print('🟢 LOGOUT FLOW recheck failed, retrying logout anyway: $e');
      }

      context.read<DriverMenuBloc>().add(const DriverLogoutPressed());
    });
  }

  void _onDriverMenuAction(BuildContext context, DriverMenuActionType action) {
    final Widget screen;
    switch (action) {
      case DriverMenuActionType.profile:
        screen = const ProfileScreen();
      case DriverMenuActionType.guidelines:
        screen = const GuidelinesScreen();
      case DriverMenuActionType.help:
        screen = const HelpScreen();
      case DriverMenuActionType.logout:
        // Handled by DriverMenuLogoutSuccess/Failure
        return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    // Reset state so the same action can be handled again later
    context.read<DriverMenuBloc>().add(const DriverMenuReset());
  }

  void _onDriverStatusState(BuildContext context, DriverStatusState state) {
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
        context.read<DriverStatusBloc>().add(const DriverBreakToggled(true));
      });
    } else if (state is DriverStatusError) {
      SnackBars.showErrorSnackBar(context, state.message);
    }
  }

  /// Remembers the blocs for timer callbacks and refreshes assignments.
  void _bindBlocsAndRefresh(BuildContext context) {
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
  }

  Widget _buildHome(BuildContext context) {
    return BlocBuilder<DriverMenuBloc, DriverMenuState>(
      builder: (context, menuState) {
        return BlocBuilder<DriverStatusBloc, DriverStatusState>(
          builder: (context, statusState) {
            // Logout has its own app-wide loader
            // (LogoutProgressOverlay); only the break toggle is
            // blocked from here.
            final shouldBlockActions = statusState is DriverBreakToggleLoading;

            return Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    try {
                      final assignedBloc =
                          context.read<AssignedSessionsBackgroundBloc>();
                      assignedBloc.add(const RefreshAssignedSessions());
                    } catch (e) {
                      print('Manual WebSocket refresh failed: $e');
                    }
                  },
                  child: DriverHomeView(
                    homeResetNotifier: _homeResetNotifier,
                  ),
                ),
                if (shouldBlockActions) const ActionBlockingLoader(),
              ],
            );
          },
        );
      },
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
          _bindBlocsAndRefresh(context);

          return MultiBlocListener(
            listeners: [
              BlocListener<AssignedSessionsBackgroundBloc,
                  AssignedSessionsBackgroundState>(
                listener: _onAssignedSessionsState,
              ),
              BlocListener<DriverMenuBloc, DriverMenuState>(
                listener: _onDriverMenuState,
              ),
              BlocListener<DriverStatusBloc, DriverStatusState>(
                listener: _onDriverStatusState,
              ),
            ],
            child: _buildHome(context),
          );
        },
      ),
    );
  }
}
