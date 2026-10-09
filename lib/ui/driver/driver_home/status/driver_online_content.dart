import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/api/driver/sessions_pending_api.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/bloc/driver/tag_submission/tag_submission_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/driver/tag_submission/tag_submission_state.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/driver/driver_home/status/driver_action_card.dart';
import 'package:niloufer_valet_mobile/ui/driver/driver_home/status/driver_vehicle_details_screen.dart';
import 'package:niloufer_valet_mobile/ui/driver/retrival_request/pending_retrieval_requests_screen.dart';
import 'package:niloufer_valet_mobile/services/oauth/session_manager.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';
import 'package:niloufer_valet_mobile/services/offline_sync/offline_parking_service.dart';
import 'package:niloufer_valet_mobile/ui/oauth/login/login.dart';

class DriverOnlineContent extends StatefulWidget {
  final String driverName;
  final int retrievePendingCount;
  final double screenWidth;
  final double screenHeight;
  final bool isTablet;
  final bool isDesktop;
  final bool showParkFlow;
  final ValueChanged<bool> onParkFlowChanged;

  const DriverOnlineContent({
    super.key,
    required this.driverName,
    this.retrievePendingCount = 0,
    required this.screenWidth,
    required this.screenHeight,
    required this.isTablet,
    required this.isDesktop,
    required this.showParkFlow,
    required this.onParkFlowChanged,
  });

  @override
  State<DriverOnlineContent> createState() => _DriverOnlineContentState();
}

class _DriverOnlineContentState extends State<DriverOnlineContent>
    with WidgetsBindingObserver {
  // Poll interval for backend session cancellation detection.
  // Backend cancels after inactivity; we check every 5 mins as requested.
  static const Duration _pendingSessionPollInterval = Duration(seconds: 2);

  Timer? _pendingSessionPollTimer;
  bool _pendingSessionWatchdogStarted = false;
  bool _handlingPendingCancellation = false;

  void _startPendingSessionWatchdog() {
    if (_pendingSessionWatchdogStarted) return;
    _pendingSessionWatchdogStarted = true;
    _pendingSessionPollTimer = Timer.periodic(_pendingSessionPollInterval, (_) {
      // Fire-and-forget; errors are handled inside the async check.
      _checkPendingSessionCancellation();
    });
  }

  void _stopPendingSessionWatchdog() {
    _pendingSessionPollTimer?.cancel();
    _pendingSessionPollTimer = null;
    _pendingSessionWatchdogStarted = false;
  }

  Future<void> _checkPendingSessionCancellation() async {
    if (!mounted || _handlingPendingCancellation) return;
    final sessionId = await TokenStorage.getSessionId();
    if (sessionId == null || sessionId.isEmpty) return;
    if (OfflineParkingService.isOfflineSessionId(sessionId)) return;

    try {
      final pending = await SessionsPendingApiService.getPendingSessions();
      final stillPending =
          pending.sessions.any((s) => s.sessionId == sessionId);

      // Backend cancelled/expired the session if it's no longer returned.
      if (!stillPending) {
        _handlingPendingCancellation = true;
        await _handlePendingSessionCancelled();
      }
    } catch (_) {
      // Ignore temporary network/API issues and try again on next poll.
    }
  }

  Future<void> _handlePendingSessionCancelled() async {
    // Prevent multiple redirects if several poll ticks overlap.
    _stopPendingSessionWatchdog();

    // Clear stored session so next flow starts clean.
    await TokenStorage.clearSessionId();

    if (!mounted) return;

    // 1) Return to the first Home screen cards (Park Vehicle | Retrieve).
    widget.onParkFlowChanged(false);

    // 2) Pop any "next screens" (CarPhotoIntro / CarCamera / Preview) above DriverHome.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true)
          .popUntil((route) => route.isFirst);
      _handlingPendingCancellation = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPendingSessionWatchdog();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DriverOnlineContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showParkFlow && !oldWidget.showParkFlow) {
      _startPendingSessionWatchdog();
      // Run an initial check right after entering the QR/tag flow.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkPendingSessionCancellation();
      });
    } else if (!widget.showParkFlow && oldWidget.showParkFlow) {
      _handlingPendingCancellation = false;
      _stopPendingSessionWatchdog();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When user reopens the app (brings to foreground), parent resets showParkFlow via key reset.
  }

  /// First screen: two cards (Park Vehicle | Retrieve Vehicle). Park tappable → Vehicle details.
  Widget _buildFirstScreen(AppTranslationsNotifier t) {
    final w = widget.screenWidth;
    final h = widget.screenHeight;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: h * 0.02),
                  TextComponent(
                    labelText:
                        '${t.getByKey('hiGreeting', TextConstants.hiGreeting)} ${widget.driverName},',
                    fontSize: w * 0.048,
                    textAlign: TextAlign.center,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                  SizedBox(height: h * 0.025),
                  DriverActionCard(
                    imagePath: 'assets/images/park.png',
                    buttonLabel: t.get(TextConstants.parkVehicle),
                    onTap: () => widget.onParkFlowChanged(true),
                    screenWidth: widget.screenWidth,
                    screenHeight: widget.screenHeight,
                    isTablet: widget.isTablet,
                    isDesktop: widget.isDesktop,
                  ),
                  SizedBox(height: h * 0.04),
                  DriverActionCard(
                    imagePath: 'assets/images/retrive.png',
                    buttonLabel: t.get(TextConstants.retrieveVehicle),
                    notificationCount: widget.retrievePendingCount,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const PendingRetrievalRequestsScreen(),
                        ),
                      );
                    },
                    screenWidth: widget.screenWidth,
                    screenHeight: widget.screenHeight,
                    isTablet: widget.isTablet,
                    isDesktop: widget.isDesktop,
                  ),
                  SizedBox(height: h * 0.025),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleDetailsScreen() {
    return DriverVehicleDetailsScreen(
      screenWidth: widget.screenWidth,
      screenHeight: widget.screenHeight,
      isTablet: widget.isTablet,
      isDesktop: widget.isDesktop,
      onReturnFromCarCamera: () => widget.onParkFlowChanged(false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return BlocProvider(
      create: (_) => TagSubmissionBloc(),
      child: BlocListener<TagSubmissionBloc, TagSubmissionState>(
        listener: (context, state) async {
          if (state is TagSubmissionSuccess) {
            SnackBars.showSuccessSnackBar(
              context,
              state.message,
            );

            // Session is now created; start/refresh the cancellation watchdog immediately.
            _startPendingSessionWatchdog();
            await _checkPendingSessionCancellation();
          } else if (state is TagSubmissionSessionExpired) {
            await TokenStorage.clearAll();
            await SessionManager.clearSessionFlags();
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const LoginScreen(),
              ),
              (route) => false,
            );
          } else if (state is TagSubmissionError) {
            SnackBars.showErrorSnackBar(
              context,
              t.get(
                state.message.toString(),
              ),
            );
          }
        },
        child: widget.showParkFlow
            ? _buildVehicleDetailsScreen()
            : _buildFirstScreen(t),
      ),
    );
  }
}
