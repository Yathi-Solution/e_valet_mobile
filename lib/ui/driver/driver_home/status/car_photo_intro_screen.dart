import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:camera/camera.dart';
import 'package:lottie/lottie.dart';
import 'package:niloufer_valet_mobile/api/driver/sessions_pending_api.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/custom_app_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/card_number_badge.dart';
import 'package:niloufer_valet_mobile/ui/driver/car_Camera/car_Camer_widgets/camera_preview_widget.dart';
import 'package:niloufer_valet_mobile/ui/driver/car_Camera/car_Camer_widgets/camera_top_overlay.dart';
import 'package:niloufer_valet_mobile/ui/driver/preview_car/preview_Car_Screen.dart';
import 'package:niloufer_valet_mobile/bloc/driver/car_camera/car_Camer_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/driver/car_camera/car_camera_event.dart';
import 'package:niloufer_valet_mobile/bloc/driver/car_camera/car_Camera_State.dart';
import 'package:niloufer_valet_mobile/services/oauth/session_manager.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';
import 'package:niloufer_valet_mobile/services/offline_sync/offline_parking_service.dart';
import 'package:niloufer_valet_mobile/ui/driver/driver_home/park_flow_signals.dart';

/// Third screen: Car Photo only — Lottie (Carphoto.json) 2 sec then camera → Capture → Preview (user enters parking location, taps Done) → Park/Repark API → Car Success.
/// When [sessionId] is provided (e.g. from pending session / card), it is saved so submit uses it; [isReparking] is passed to the Park API.
class CarPhotoIntroScreen extends StatefulWidget {
  final bool cameViaTagNumber;
  final VoidCallback? onReturnFromCamera;
  final String? cardNumber;

  /// When opening from a pending session (e.g. CHECKED_IN card), pass sessionId so the screen can submit without scanning first.
  final String? sessionId;

  /// True when continuing a reparking flow (pending REPARKING).
  final bool isReparking;

  const CarPhotoIntroScreen({
    super.key,
    required this.cameViaTagNumber,
    this.onReturnFromCamera,
    this.cardNumber,
    this.sessionId,
    this.isReparking = false,
  });

  @override
  State<CarPhotoIntroScreen> createState() => _CarPhotoIntroScreenState();
}

class _CarPhotoIntroScreenState extends State<CarPhotoIntroScreen>
    with WidgetsBindingObserver {
  static const Duration _pendingSessionPollInterval = Duration(minutes: 5);

  /// 0 = Lottie, 1 = camera (only Car Photo flow now)
  int _selectedTab = 1;

  /// 0 = Lottie (2 sec), 1 = camera in same area (only when on Scan tab)
  int _scanPhase = 0;
  Timer? _lottieTimer;
  Timer? _pendingSessionPollTimer;
  late CarCameraBloc _cameraBloc;
  bool _isCapturing = false;
  bool _isHandlingCancellation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ParkFlowSignals.beginCarPhotoParkFlow();
    _cameraBloc = CarCameraBloc();
    _selectedTab = 1;
    _scanPhase = 0;
    if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
      TokenStorage.saveSessionId(widget.sessionId!).catchError((e) {
        debugPrint('[CarPhotoIntro] Failed to save sessionId: $e');
      });
    }
    // Show car photo intro (Lottie) only once per login session; when user comes back
    // (e.g. another card in same session) skip animation and show camera. Flags cleared on logout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initCarPhotoIntro();
    });
    _startPendingSessionPolling();
  }

  void _startPendingSessionPolling() {
    _pendingSessionPollTimer?.cancel();
    _pendingSessionPollTimer = Timer.periodic(_pendingSessionPollInterval, (_) {
      _checkPendingSessionCancellation();
    });
    _checkPendingSessionCancellation();
  }

  Future<void> _checkPendingSessionCancellation() async {
    if (!mounted || _isHandlingCancellation) return;
    final sessionId = await TokenStorage.getSessionId();
    if (sessionId == null || sessionId.isEmpty) return;
    if (OfflineParkingService.isOfflineSessionId(sessionId)) return;

    try {
      final pending = await SessionsPendingApiService.getPendingSessions();
      final stillExists = pending.sessions.any((s) => s.sessionId == sessionId);
      if (!stillExists) {
        await _redirectToHomeOnCancellation();
      }
    } catch (_) {
      // Ignore transient errors and retry on next poll tick.
    }
  }

  Future<void> _redirectToHomeOnCancellation() async {
    if (_isHandlingCancellation) return;
    _isHandlingCancellation = true;
    _pendingSessionPollTimer?.cancel();
    _pendingSessionPollTimer = null;
    await TokenStorage.clearSessionId();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true)
          .popUntil((route) => route.isFirst);
      _isHandlingCancellation = false;
    });
  }

  Future<void> _initCarPhotoIntro() async {
    final alreadyShown =
        await SessionManager.hasShownCarPhotoIntroThisSession();
    if (!mounted) return;
    if (alreadyShown) {
      setState(() => _scanPhase = 1);
      _cameraBloc.add(const InitializeCameraRequested());
      return;
    }
    _startLottieTimer();
  }

  void _startLottieTimer() {
    _lottieTimer?.cancel();
    // Mark intro as shown immediately so it is only visible once per login even if user leaves before 2s
    SessionManager.markCarPhotoIntroShown();
    _lottieTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      _lottieTimer = null;
      setState(() {
        _scanPhase = 1;
      });
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _cameraBloc.add(const InitializeCameraRequested());
      });
    });
  }

  /// Navigate to preview screen so user can confirm and submit from there (Park/Repark API runs on preview submit).
  Future<void> _navigateToPreview(
    BuildContext context, {
    String? imagePath,
    String? parkingLocation,
    String? vehicleNumber,
  }) async {
    debugPrint(
        '[CarPhotoIntro] _navigateToPreview: imagePath=$imagePath, parkingLocation=$parkingLocation, vehicleNumber=$vehicleNumber');
    if (!mounted) return;
    try {
      final sessionId = await TokenStorage.getSessionId();
      if (!mounted) return;
      if (sessionId == null || sessionId.isEmpty) {
        SnackBars.showErrorSnackBar(
          context,
          'No active session. Please scan or enter badge number first.',
        );
        return;
      }
      if (!mounted) return;
      final isFromScan = imagePath != null && imagePath.isNotEmpty;
      _cameraBloc.add(const DisposeCameraRequested());
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PreviewCarScreen(
            imagePath: imagePath,
            sessionId: sessionId,
            isReparking: widget.isReparking,
            parkingLocation: parkingLocation,
            vehicleNumber: vehicleNumber,
            cardNumber: widget.cardNumber,
          ),
        ),
      );
      // After dispose-before-preview, controller is gone — full re-init for Retake.
      if (mounted && isFromScan && _selectedTab == 1) {
        _cameraBloc.add(const InitializeCameraRequested());
      }
    } catch (e) {
      debugPrint('[CarPhotoIntro] _navigateToPreview error: $e');
      if (mounted) {
        SnackBars.showErrorSnackBar(
          context,
          'Unable to open preview. Please try again.',
        );
      }
    }
  }

  void _onCapturePhoto(BuildContext ctx) async {
    final state = ctx.read<CarCameraBloc>().state;
    if (state is! CarCameraInitialized &&
        state is! CarCameraFlashToggled &&
        state is! CarCameraValidationError) {
      SnackBars.showErrorSnackBar(ctx, TextConstants.cameraNotReady);
      return;
    }
    if (_isCapturing) return;
    try {
      _isCapturing = true;
      final cameraController = state is CarCameraInitialized
          ? state.cameraController
          : state is CarCameraFlashToggled
              ? state.cameraController
              : (state as CarCameraValidationError).cameraController;
      final isFlashOn = state is CarCameraInitialized
          ? state.isFlashOn
          : state is CarCameraFlashToggled
              ? state.isFlashOn
              : (state as CarCameraValidationError).isFlashOn;
      if (!cameraController.value.isInitialized) {
        SnackBars.showErrorSnackBar(ctx, TextConstants.cameraNotReady);
        return;
      }
      await cameraController.setFlashMode(
        isFlashOn ? FlashMode.always : FlashMode.off,
      );
      final image = await cameraController.takePicture();
      if (cameraController.value.isInitialized) {
        await cameraController.setFlashMode(
          isFlashOn ? FlashMode.torch : FlashMode.off,
        );
      }
      ctx.read<CarCameraBloc>().add(const ValidationReset());
      if (mounted) {
        ctx.read<CarCameraBloc>().add(ValidateImageRequested(image.path));
      }
    } catch (e) {
      if (mounted) {
        SnackBars.showErrorSnackBar(
          ctx,
          '${TextConstants.errorCapturingPhoto}: $e',
        );
      }
    } finally {
      if (mounted) _isCapturing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _cameraBloc.add(const DisposeCameraRequested());
      return;
    }
    if (state == AppLifecycleState.resumed &&
        _selectedTab == 1 &&
        _scanPhase == 1) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          _cameraBloc.add(const InitializeCameraRequested());
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ParkFlowSignals.endCarPhotoParkFlow();
    _lottieTimer?.cancel();
    _pendingSessionPollTimer?.cancel();
    _cameraBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return BlocProvider<CarCameraBloc>.value(
      value: _cameraBloc,
      child: BlocListener<CarCameraBloc, CarCameraState>(
        listener: (context, state) {
          if (state is CarCameraValidationSuccess) {
            _navigateToPreview(context, imagePath: state.imagePath);
          } else if (state is CarCameraValidationError) {
            SnackBars.showErrorSnackBar(context, state.message);
            context.read<CarCameraBloc>().add(const ValidationReset());
          }
        },
        child: Builder(
          builder: (bodyContext) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop && mounted) {
                  SnackBars.showErrorSnackBar(
                    context,
                    t.get(TextConstants.pleaseCompleteParkingProcess),
                  );
                }
              },
              child: Scaffold(
                backgroundColor: AppColors.lightBeigeBackground,
                appBar: const CustomAppBar(showOverflowMenu: true),
                body: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: h * 0.016),
                      _buildHeaderAboveTabs(t, w, h),
                      SizedBox(height: h * 0.016),
                      Expanded(
                        child: _buildScanTabContent(w, h),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Same style as driver_qr_scanner_content: title + "what to do" hint above the tabs.
  Widget _buildHeaderAboveTabs(
    AppTranslationsNotifier t,
    double w,
    double h,
  ) {
    final hasCardNumber =
        widget.cardNumber != null && widget.cardNumber!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: h * 0.012,
        horizontal: w * 0.04,
      ),
      color: AppColors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: hasCardNumber
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                TextComponent(
                  labelText: t.getByKey(
                      'vehicleDetailsTitle', TextConstants.vehicleDetailsTitle),
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                  textAlign: hasCardNumber ? TextAlign.start : TextAlign.center,
                ),
                SizedBox(height: h * 0.006),
                TextComponent(
                  labelText: t.getByKey('vehicleDetailsParkingPhotoHint',
                      TextConstants.vehicleDetailsParkingPhotoHint),
                  fontSize: w * 0.032,
                  fontWeight: FontWeight.w400,
                  color: AppColors.black,
                  textAlign: hasCardNumber ? TextAlign.start : TextAlign.center,
                ),
              ],
            ),
          ),
          if (hasCardNumber) ...[
            SizedBox(width: w * 0.03),
            CardNumberBadge(
              label: t.get(TextConstants.cardNumberLabel),
              value: widget.cardNumber!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanTabContent(double w, double h) {
    final padding = w * 0.02;
    if (_scanPhase == 0) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.mutedText,
            borderRadius: BorderRadius.circular(w * 0.04),
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.transparent,
                      borderRadius: BorderRadius.circular(w * 0.04),
                      border: Border.all(color: AppColors.white, width: 2.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Lottie.asset(
                      'assets/jsons/Carphoto.json',
                      fit: BoxFit.contain,
                      repeat: false,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: h * 0.018,
                child: Container(
                  width: w * 0.2,
                  height: w * 0.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.actionButtonYellow,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Phase 1: camera in same area (same layout as old camera: preview + flash + capture)
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.mutedText,
          borderRadius: BorderRadius.circular(w * 0.04),
        ),
        clipBehavior: Clip.antiAlias,
        child: BlocBuilder<CarCameraBloc, CarCameraState>(
          builder: (context, state) {
            final isReady = state is CarCameraInitialized ||
                state is CarCameraFlashToggled ||
                state is CarCameraValidationError;
            final controller = state is CarCameraInitialized
                ? state.cameraController
                : state is CarCameraFlashToggled
                    ? state.cameraController
                    : state is CarCameraValidationError
                        ? state.cameraController
                        : null;
            final isFlashOn = state is CarCameraInitialized
                ? state.isFlashOn
                : state is CarCameraFlashToggled
                    ? state.isFlashOn
                    : state is CarCameraValidationError
                        ? state.isFlashOn
                        : false;
            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.white, width: 2.5),
                      borderRadius: BorderRadius.circular(w * 0.04),
                    ),
                    child: CameraPreviewWidget(
                      isCameraInitialized: isReady && controller != null,
                      cameraController: controller,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: CameraTopOverlay(
                    isFlashOn: isFlashOn,
                    onFlashToggle: () => context
                        .read<CarCameraBloc>()
                        .add(const ToggleFlashRequested()),
                    topOffset: 0,
                  ),
                ),
                Positioned(
                  bottom: h * 0.018,
                  child: Material(
                    color: AppColors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (_isCapturing) return;
                        final s = context.read<CarCameraBloc>().state;
                        if (s is CarCameraInitialized ||
                            s is CarCameraFlashToggled ||
                            s is CarCameraValidationError) {
                          _onCapturePhoto(context);
                        }
                      },
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: w * 0.2,
                        height: w * 0.2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.actionButtonYellow,
                          border: Border.all(color: AppColors.white, width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
