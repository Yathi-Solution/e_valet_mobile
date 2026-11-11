import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:evalet/services/translations/app_translations_notifier.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:evalet/api/driver/initiate_repark_api_service.dart';
import 'package:evalet/api/driver/assigned_sessions_api_service.dart';
import 'package:evalet/api/driver/sessions_pending_api.dart';
import 'package:evalet/api/operator/operator_dashboard/operator_assign_retrieval_api_service.dart';
import 'package:evalet/bloc/driver/confirm_arrival/confirm_arrival_bloc.dart';
import 'package:evalet/bloc/driver/confirm_arrival/confirm_arrival_event.dart';
import 'package:evalet/bloc/driver/confirm_arrival/confirm_arrival_state.dart';
import 'package:evalet/models/driver/session/assigned_session.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/text_constants.dart';
import 'package:evalet/ui/common/widgets/custom_app_bar.dart';
import 'package:evalet/ui/common/widgets/footer.dart';
import 'package:evalet/ui/common/widgets/snack_bar.dart';
import 'package:evalet/ui/common/widgets/text.dart';
import 'package:evalet/ui/driver/driver_home/status/car_photo_intro_screen.dart';
import 'package:evalet/ui/driver/driver_home/driver_home.dart';
import 'package:evalet/ui/driver/confirm_arrival/car_details_screen.dart';
import 'package:evalet/ui/driver/confirm_arrival/confirm_arrival_flow_tracker.dart';
import 'package:evalet/ui/driver/confirm_arrival/confirm_arrival_widgets/car_information_card.dart';
import 'package:evalet/ui/driver/confirm_arrival/confirm_arrival_widgets/handover_buttons_section.dart';
import 'package:evalet/ui/driver/confirm_arrival/confirm_arrival_widgets/slide_to_confirm_button.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/driver/re-park/initiate_repark_request.dart';
import 'package:evalet/services/location/location_service.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';

class ConfirmArrivalScreen extends StatefulWidget {
  final AssignedSession session;
  final bool preventBackNavigation;
  final bool showHandoverOnLoad;

  /// When set, the disable countdown is counted from this moment (when accept API was triggered).
  /// Passed from Collect Keys flow so the button enables after CONFIRM_ARRIVAL_DISABLE_SECONDS, not after screen open.
  final DateTime? acceptTriggeredAt;

  /// Total seconds the button stays disabled after acceptTriggeredAt. If null, uses CONFIRM_ARRIVAL_DISABLE_SECONDS from .env (default 10).
  final int? disableConfirmArrivalForSeconds;

  const ConfirmArrivalScreen({
    super.key,
    required this.session,
    this.preventBackNavigation = false,
    this.showHandoverOnLoad = false,
    this.acceptTriggeredAt,
    this.disableConfirmArrivalForSeconds,
  });

  @override
  State<ConfirmArrivalScreen> createState() => _ConfirmArrivalScreenState();
}

/// Polling interval in seconds to detect operator override (Parked/Completed).
const int _operatorOverridePollIntervalSeconds = 5;

class _ConfirmArrivalScreenState extends State<ConfirmArrivalScreen> {
  bool _showHandoverButtons = false;
  bool _confirmArrivalButtonEnabled = true;
  int _confirmArrivalRemainingSeconds = 0;
  Timer? _enableConfirmArrivalTimer;
  Timer? _operatorOverridePollTimer;

  /// True after user taps Confirm Handover — in-flight [_checkOperatorOverride] must not pop,
  /// or it races with [ConfirmHandoverSuccess] and causes a double pop → blank navigator.
  bool _userHandoverRequestInFlight = false;

  /// Ensures only one [Navigator.pop] is scheduled (operator complete + handover success overlap).
  bool _navigationPopScheduled = false;

  /// After Confirm Arrival API success, Customer Missing button is disabled until this time (duration from CUSTOMER_MISSING_DISABLE_SECONDS in .env).
  DateTime? _customerMissingDisabledUntil;
  DateTime? _confirmHandoverDisabledUntil;

  bool _isNotAssignedToRetrievalError(String message) {
    final msg = message.toLowerCase();
    return msg.contains('not assigned') && msg.contains('retrieval request');
  }

  static int _confirmArrivalDisableSecondsFromEnv() {
    final fromStorage = TokenStorage.getConfirmArrivalDisableSecondsSync();
    if (fromStorage != null && fromStorage > 0) return fromStorage;
    final v = dotenv.env['CONFIRM_ARRIVAL_DISABLE_SECONDS'];
    if (v == null || v.isEmpty) return 10;
    return int.tryParse(v.trim()) ?? 10;
  }

  static int _customerMissingDisableSecondsFromEnv() {
    final fromStorage = TokenStorage.getCustomerMissingDisableSecondsSync();
    if (fromStorage != null && fromStorage > 0) return fromStorage;
    final v = dotenv.env['CUSTOMER_MISSING_DISABLE_SECONDS'];
    if (v == null || v.isEmpty) return 60;
    return int.tryParse(v.trim()) ?? 60;
  }

  static int _confirmHandoverDisableSecondsFromEnv() {
    final fromStorage = TokenStorage.getConfirmHandoverDisableSecondsSync();
    if (fromStorage != null && fromStorage > 0) return fromStorage;
    final v = dotenv.env['CONFIRM_HANDOVER_DISABLE_SECONDS'];
    if (v == null || v.isEmpty) return 10;
    return int.tryParse(v.trim()) ?? 10;
  }

  void _startConfirmArrivalCountdownOnEnter() {
    _enableConfirmArrivalTimer?.cancel();
    final totalSeconds = widget.disableConfirmArrivalForSeconds ??
        _confirmArrivalDisableSecondsFromEnv();
    if (totalSeconds <= 0) {
      _confirmArrivalButtonEnabled = true;
      _confirmArrivalRemainingSeconds = 0;
      return;
    }

    final now = DateTime.now();
    final persisted = TokenStorage.getConfirmArrivalDisabledUntilForSessionSync(
      widget.session.id,
      cardNumber: widget.session.cardNumber,
    );
    final alreadyStarted =
        TokenStorage.hasConfirmArrivalTimerStartedForSessionSync(
      widget.session.id,
      cardNumber: widget.session.cardNumber,
    );

    DateTime? disabledUntil = persisted;
    if (alreadyStarted &&
        (disabledUntil == null || !disabledUntil.isAfter(now))) {
      _confirmArrivalButtonEnabled = true;
      _confirmArrivalRemainingSeconds = 0;
      return;
    }

    if (disabledUntil == null || !disabledUntil.isAfter(now)) {
      final fromAccept = widget.acceptTriggeredAt;
      if (fromAccept != null) {
        disabledUntil = fromAccept.add(Duration(seconds: totalSeconds));
      } else {
        disabledUntil = now.add(Duration(seconds: totalSeconds));
      }
      TokenStorage.markConfirmArrivalTimerStartedForSessionSync(
        widget.session.id,
        cardNumber: widget.session.cardNumber,
      );
      TokenStorage.saveConfirmArrivalDisabledUntilForSessionSync(
        widget.session.id,
        disabledUntil,
        cardNumber: widget.session.cardNumber,
      );
    }

    final remaining = disabledUntil.difference(now).inSeconds;
    if (remaining <= 0) {
      _confirmArrivalButtonEnabled = true;
      _confirmArrivalRemainingSeconds = 0;
      return;
    }

    _confirmArrivalButtonEnabled = false;
    _confirmArrivalRemainingSeconds = remaining;
    _enableConfirmArrivalTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;
        setState(() {
          _confirmArrivalRemainingSeconds =
              (_confirmArrivalRemainingSeconds - 1).clamp(0, remaining);
          if (_confirmArrivalRemainingSeconds <= 0) {
            _enableConfirmArrivalTimer?.cancel();
            _enableConfirmArrivalTimer = null;
            _confirmArrivalButtonEnabled = true;
          }
        });
      },
    );
  }

  void _ensureHandoverCooldownStarted() {
    final persisted =
        TokenStorage.getConfirmHandoverDisabledUntilForSessionSync(
      widget.session.id,
      cardNumber: widget.session.cardNumber,
    );
    final alreadyStarted =
        TokenStorage.hasConfirmHandoverTimerStartedForSessionSync(
      widget.session.id,
      cardNumber: widget.session.cardNumber,
    );
    if (alreadyStarted &&
        (persisted == null || !persisted.isAfter(DateTime.now()))) {
      _confirmHandoverDisabledUntil = null;
      return;
    }
    if (persisted != null && persisted.isAfter(DateTime.now())) {
      _confirmHandoverDisabledUntil = persisted;
      return;
    }

    final until = _confirmHandoverDisabledUntil;
    if (until != null && until.isAfter(DateTime.now())) return;
    final secs = _confirmHandoverDisableSecondsFromEnv();
    if (secs <= 0) {
      _confirmHandoverDisabledUntil = null;
      return;
    }
    final newUntil = DateTime.now().add(Duration(seconds: secs));
    _confirmHandoverDisabledUntil = newUntil;
    TokenStorage.markConfirmHandoverTimerStartedForSessionSync(
      widget.session.id,
      cardNumber: widget.session.cardNumber,
    );
    TokenStorage.saveConfirmHandoverDisabledUntilForSessionSync(
      widget.session.id,
      newUntil,
      cardNumber: widget.session.cardNumber,
    );
  }

  void _ensureCustomerMissingCooldownStarted() {
    final persisted =
        TokenStorage.getCustomerMissingDisabledUntilForSessionSync(
      widget.session.id,
      cardNumber: widget.session.cardNumber,
    );
    if (persisted != null && persisted.isAfter(DateTime.now())) {
      _customerMissingDisabledUntil = persisted;
      return;
    }

    final until = _customerMissingDisabledUntil;
    if (until != null && until.isAfter(DateTime.now())) return;
    final secs = _customerMissingDisableSecondsFromEnv();
    if (secs <= 0) {
      _customerMissingDisabledUntil = null;
      return;
    }
    final newUntil = DateTime.now().add(Duration(seconds: secs));
    _customerMissingDisabledUntil = newUntil;
    TokenStorage.saveCustomerMissingDisabledUntilForSessionSync(
      widget.session.id,
      newUntil,
      cardNumber: widget.session.cardNumber,
    );
  }

  void _showHandoverStage({bool startCustomerMissingCooldown = false}) {
    setState(() {
      _showHandoverButtons = true;
      _ensureHandoverCooldownStarted();
      if (startCustomerMissingCooldown) {
        _ensureCustomerMissingCooldownStarted();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    ConfirmArrivalFlowTracker.setActiveSession(widget.session.id);
    _showHandoverButtons = widget.showHandoverOnLoad;
    if (_showHandoverButtons) {
      _ensureHandoverCooldownStarted();
      _ensureCustomerMissingCooldownStarted();
    } else {
      _startConfirmArrivalCountdownOnEnter();
    }
    _startOperatorOverridePolling();
  }

  /// Polls assigned sessions every 5 seconds. When operator overrides transaction
  /// status to Parked/Completed from Operator Dashboard, the session is removed
  /// from assigned-to-me. We detect that and pop to Home so valet becomes available.
  void _startOperatorOverridePolling() {
    _operatorOverridePollTimer?.cancel();
    _operatorOverridePollTimer = Timer.periodic(
      const Duration(seconds: _operatorOverridePollIntervalSeconds),
      (_) => _checkOperatorOverride(),
    );
  }

  Future<void> _checkOperatorOverride() async {
    if (!mounted) return;
    try {
      // Avoid popping while confirm arrival / handover API is in flight (race → double pop → blank screen).
      try {
        final blocState = context.read<ConfirmArrivalBloc>().state;
        if (blocState is ConfirmArrivalLoading) {
          dev.log(
            'ConfirmArrival poll: skip (bloc loading) session=${widget.session.id}',
            name: 'ConfirmArrival',
          );
          return;
        }
      } catch (_) {}

      if (_userHandoverRequestInFlight) {
        dev.log(
          'ConfirmArrival poll: skip (user handover in flight) session=${widget.session.id}',
          name: 'ConfirmArrival',
        );
        return;
      }

      if (_navigationPopScheduled) {
        dev.log(
          'ConfirmArrival poll: skip (pop already scheduled) session=${widget.session.id}',
          name: 'ConfirmArrival',
        );
        return;
      }

      // 1) GET /operators/assign-retrieval - primary source for status when operator changes in Car Logs
      final assignmentStatus =
          await OperatorAssignRetrievalApiService.getAssignmentStatus(
        sessionId: widget.session.id,
      );
      if (!mounted) return;
      if (assignmentStatus != null) {
        if (assignmentStatus.isParked || assignmentStatus.isCompleted) {
          dev.log(
            'ConfirmArrival poll: operator parked/completed → schedule pop session=${widget.session.id}',
            name: 'ConfirmArrival',
          );
          _operatorOverridePollTimer?.cancel();
          _operatorOverridePollTimer = null;
          if (mounted) {
            final t = context.read<AppTranslationsNotifier>();
            SnackBars.showSuccessSnackBar(
              context,
              t.getByKey(
                'transactionCompletedByOperator',
                TextConstants.transactionCompletedByOperator,
              ),
            );
            _safePopAfterSnackBar(reason: 'operator_assignment_status');
          }
          return;
        }
        if (!_showHandoverButtons && assignmentStatus.isArrived) {
          _showHandoverStage();
          return;
        }
      }

      // 2) Fallback: Check assigned sessions - session removed when operator completes
      final sessions = await AssignedSessionsApiService.fetchAssignedSessions();
      if (!mounted) return;
      final sessionStillAssigned =
          sessions.any((s) => s.id == widget.session.id);
      if (!sessionStillAssigned) {
        dev.log(
          'ConfirmArrival poll: session not in assigned-to-me → schedule pop session=${widget.session.id}',
          name: 'ConfirmArrival',
        );
        _operatorOverridePollTimer?.cancel();
        _operatorOverridePollTimer = null;
        if (mounted) {
          final t = context.read<AppTranslationsNotifier>();
          SnackBars.showSuccessSnackBar(
            context,
            t.getByKey(
              'transactionCompletedByOperator',
              TextConstants.transactionCompletedByOperator,
            ),
          );
          _safePopAfterSnackBar(reason: 'session_removed_assigned');
        }
        return;
      }

      // 3) Fallback: GET /sessions/pending - check if operator changed to ARRIVED
      if (!_showHandoverButtons) {
        final pending = await SessionsPendingApiService.getPendingSessions();
        if (!mounted) return;
        final matching = pending.sessions
            .where((s) => s.sessionId == widget.session.id)
            .toList();
        if (matching.isNotEmpty && matching.first.isArrived) {
          _showHandoverStage();
        }
      }
    } catch (e, st) {
      dev.log(
        'ConfirmArrival poll error session=${widget.session.id}',
        name: 'ConfirmArrival',
        error: e,
        stackTrace: st,
      );
    }
  }

  void _cancelOperatorOverridePolling() {
    _operatorOverridePollTimer?.cancel();
    _operatorOverridePollTimer = null;
  }

  Future<void> _handleCustomerMissingTap() async {
    try {
      LocationPermission permission = await LocationService.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await LocationService.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw ApiException(
          'Location permission is required to initiate repark.',
          code: 'location_permission_denied',
        );
      }

      final position = await LocationService.getCurrentLocation();

      final request = InitiateReparkRequest(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );

      final response = await InitiateReparkApiService.initiateRepark(
        sessionId: widget.session.id,
        request: request,
      );

      if (!mounted) return;
      SnackBars.showSuccessSnackBar(context, response.message);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CarPhotoIntroScreen(
            cameViaTagNumber: false,
            sessionId: widget.session.id,
            isReparking: true,
            cardNumber: widget.session.cardNumber.toString(),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      SnackBars.showErrorSnackBar(context, e.message);
    } catch (e) {
      if (!mounted) return;
      SnackBars.showErrorSnackBar(
        context,
        'Failed to initiate repark. Please try again.',
      );
    }
  }

  /// Pop once on the next frame after snackbar schedules; cancels operator polling
  /// first to avoid a race with [_checkOperatorOverride] (double pop → blank screen).
  void _safePopAfterSnackBar({required String reason}) {
    if (_navigationPopScheduled) {
      dev.log(
        'ConfirmArrival _safePopAfterSnackBar IGNORED (already scheduled) reason=$reason session=${widget.session.id}',
        name: 'ConfirmArrival',
      );
      return;
    }
    _navigationPopScheduled = true;
    TokenStorage.markRetrievalConfirmFlowCompletedCooldownSync(
      widget.session.id,
    );
    dev.log(
      'ConfirmArrival schedule pop reason=$reason session=${widget.session.id}',
      name: 'ConfirmArrival',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        dev.log(
          'ConfirmArrival pop callback: unmounted, abort session=${widget.session.id}',
          name: 'ConfirmArrival',
        );
        return;
      }
      _cancelOperatorOverridePolling();
      try {
        TokenStorage.removeCollectKeysInTransitAckForSessionSync(
            widget.session.id);
        TokenStorage.clearHandoverButtonCooldownForSessionSync(
          widget.session.id,
          cardNumber: widget.session.cardNumber,
        );
      } catch (e, st) {
        dev.log(
          'ConfirmArrival Hive removeCollectKeys error',
          name: 'ConfirmArrival',
          error: e,
          stackTrace: st,
        );
      }
      try {
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          dev.log(
            'ConfirmArrival Navigator.pop() session=${widget.session.id}',
            name: 'ConfirmArrival',
          );
          nav.pop();
        } else {
          dev.log(
            'ConfirmArrival Navigator.canPop()==false — NOT popping (would blank stack) session=${widget.session.id}',
            name: 'ConfirmArrival',
          );
        }
      } catch (e, st) {
        dev.log(
          'ConfirmArrival Navigator.pop threw',
          name: 'ConfirmArrival',
          error: e,
          stackTrace: st,
        );
      }
    });
  }

  void _goToHomeScreen() {
    _cancelOperatorOverridePolling();
    // User intentionally left retrieval flow via logo tap; suppress immediate
    // auto-resume/sheet reopen for this same session on home.
    TokenStorage.markRetrievalConfirmFlowCompletedCooldownSync(
        widget.session.id);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    dev.log(
      'ConfirmArrival dispose session=${widget.session.id}',
      name: 'ConfirmArrival',
    );
    _enableConfirmArrivalTimer?.cancel();
    _cancelOperatorOverridePolling();
    _userHandoverRequestInFlight = false;
    ConfirmArrivalFlowTracker.clearIfMatches(widget.session.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return BlocProvider(
      create: (context) => ConfirmArrivalBloc(),
      child: BlocListener<ConfirmArrivalBloc, ConfirmArrivalState>(
        listener: (context, state) {
          if (state is ConfirmArrivalSuccess) {
            SnackBars.showSuccessSnackBar(context, state.message);
            _showHandoverStage(startCustomerMissingCooldown: true);
          } else if (state is ConfirmArrivalError) {
            if (state.shouldNavigateToHandover) {
              SnackBars.showSuccessSnackBar(context, state.message);
              _showHandoverStage(startCustomerMissingCooldown: true);
            } else {
              SnackBars.showErrorSnackBar(context, state.message);
            }
          } else if (state is ConfirmHandoverSuccess) {
            dev.log(
              'ConfirmArrival bloc: ConfirmHandoverSuccess session=${widget.session.id} msg=${state.message}',
              name: 'ConfirmArrival',
            );
            if (!context.mounted) return;
            _userHandoverRequestInFlight = false;
            _cancelOperatorOverridePolling();
            SnackBars.showSuccessSnackBar(context, state.message);
            // Pop next frame so SnackBar attaches; one pop only — avoids blank stack.
            _safePopAfterSnackBar(reason: 'handover_success');
          } else if (state is ConfirmHandoverError) {
            _userHandoverRequestInFlight = false;
            dev.log(
              'ConfirmArrival bloc: ConfirmHandoverError session=${widget.session.id} ${state.message}',
              name: 'ConfirmArrival',
            );
            if (_isNotAssignedToRetrievalError(state.message)) {
              // Assignment moved away; leave stale screen instead of allowing
              // repeated handover retries on a session this valet no longer owns.
              SnackBars.showSuccessSnackBar(context, state.message);
              _safePopAfterSnackBar(reason: 'handover_not_assigned_anymore');
            } else {
              SnackBars.showErrorSnackBar(context, state.message);
            }
          }
        },
        child: BlocBuilder<ConfirmArrivalBloc, ConfirmArrivalState>(
          builder: (context, state) {
            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;
            final isLoading = state is ConfirmArrivalLoading;

            // Layout: 40% image, 30% data, 30% button (flex 4 : 3 : 3)
            final scaffoldContent = Scaffold(
              backgroundColor: AppColors.lightBeigeBackground,
              appBar: CustomAppBar(
                onLogoTap: _goToHomeScreen,
                showOverflowMenu: true,
              ),
              body: Column(
                children: [
                  SizedBox(height: screenHeight * 0.01),
                  Center(
                    child: TextComponent(
                      labelText: t.get(TextConstants.retrievalRequest),
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.008),
                  // 40% – image
                  Expanded(
                    flex: 4,
                    child: CarImageSection(session: widget.session),
                  ),
                  SizedBox(height: screenHeight * 0.008),
                  // 30% – data
                  Expanded(
                    flex: 3,
                    child: CarDetailsSection(session: widget.session),
                  ),
                  SizedBox(height: screenHeight * 0.008),
                  // 30% – instruction + button(s)
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.01,
                      ),
                      child: _showHandoverButtons
                          ? HandoverButtonsSection(
                              isLoading: isLoading,
                              customerMissingDisabledUntil:
                                  _customerMissingDisabledUntil,
                              confirmHandoverDisabledUntil:
                                  _confirmHandoverDisabledUntil,
                              onConfirmHandover: () {
                                dev.log(
                                  'ConfirmArrival UI: ConfirmHandover tap session=${widget.session.id}',
                                  name: 'ConfirmArrival',
                                );
                                setState(() {
                                  _userHandoverRequestInFlight = true;
                                });
                                context.read<ConfirmArrivalBloc>().add(
                                      ConfirmHandoverRequested(
                                          sessionId: widget.session.id),
                                    );
                              },
                              onCustomerMissing: () {
                                return _handleCustomerMissingTap();
                              },
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextComponent(
                                  labelText: t.getByKey(
                                      'pressBelowToConfirmArrival',
                                      TextConstants.pressBelowToConfirmArrival),
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.black,
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                Expanded(
                                  child: SlideToConfirmButton(
                                    sessionId: widget.session.id,
                                    isLoading: isLoading,
                                    enabled: _confirmArrivalButtonEnabled,
                                    disabledRemainingSeconds:
                                        _confirmArrivalRemainingSeconds,
                                    onConfirm: () {
                                      context.read<ConfirmArrivalBloc>().add(
                                            ConfirmArrivalRequested(
                                                sessionId: widget.session.id),
                                          );
                                    },
                                    useBigStyle: true,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const Footer(),
                ],
              ),
            );

            // Wrap with PopScope to prevent back navigation if needed
            if (widget.preventBackNavigation) {
              return PopScope(
                canPop: false, // Prevent back button from navigating back
                child: scaffoldContent,
              );
            }

            return scaffoldContent;
          },
        ),
      ),
    );
  }
}
