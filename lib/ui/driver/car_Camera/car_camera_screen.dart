import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:evalet/api/driver/sessions_pending_api.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';
import 'package:evalet/ui/driver/driver_home/park_flow_signals.dart';
import 'package:evalet/ui/common/widgets/custom_app_bar.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/text_constants.dart';
import 'package:evalet/ui/common/widgets/snack_bar.dart';
import 'package:evalet/ui/driver/preview_car/preview_Car_Screen.dart';
import 'package:evalet/bloc/driver/car_camera/car_Camer_bloc.dart';
import 'package:evalet/bloc/driver/car_camera/car_camera_event.dart';
import 'package:evalet/bloc/driver/car_camera/car_Camera_State.dart';
import 'package:evalet/ui/driver/car_Camera/car_Camer_widgets/camera_preview_widget.dart';
import 'package:evalet/ui/driver/car_Camera/car_Camer_widgets/camera_top_overlay.dart';
import 'package:evalet/ui/driver/car_Camera/car_Camer_widgets/camera_bottom_overlay.dart';

class CarCameraScreen extends StatefulWidget {
  final String? sessionId;
  final bool isReparking;
  final bool preventBackNavigation;
  final String? cardNumber;

  /// Pre-fill parking location (e.g. from third screen tag flow).
  final String? initialParkingLocation;

  const CarCameraScreen({
    super.key,
    this.sessionId,
    this.isReparking = false,
    this.preventBackNavigation = false,
    this.initialParkingLocation,
    this.cardNumber,
  });

  @override
  State<CarCameraScreen> createState() => _CarCameraScreenState();
}

class _CarCameraScreenState extends State<CarCameraScreen>
    with WidgetsBindingObserver, RouteAware {
  static const Duration _pendingSessionPollInterval = Duration(minutes: 5);

  late CarCameraBloc _cameraBloc;
  bool _isInitializing = false;
  bool _isCapturing = false;
  RouteObserver<ModalRoute>? _routeObserver;
  Orientation? _currentOrientation;
  Timer? _pendingSessionPollTimer;
  bool _isHandlingCancellation = false;

  @override
  void initState() {
    super.initState();
    _cameraBloc = CarCameraBloc();
    _routeObserver = RouteObserver<ModalRoute>();
    WidgetsBinding.instance.addObserver(this);
    // Set preferred orientations to allow landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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
    // A park submit is in flight: the session leaving the pending list is expected.
    if (ParkFlowSignals.isParkSubmitInProgress) return;
    final sessionId = await TokenStorage.getSessionId();
    if (sessionId == null || sessionId.isEmpty) return;

    try {
      final pending = await SessionsPendingApiService.getPendingSessions();
      final stillExists = pending.sessions.any((s) => s.sessionId == sessionId);
      // The park may have completed while this request was in flight; a
      // parked session is no longer "pending" but it was not cancelled.
      if (ParkFlowSignals.isParkSubmitInProgress) return;
      if (await TokenStorage.getSessionId() != sessionId) return;
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeObserver?.subscribe(this, ModalRoute.of(context)!);
    // Clear any global "no internet" banner so it never shows over the camera
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).clearMaterialBanners();
    });
    // Only initialize if not already initializing
    // Add a small delay to ensure camera service is ready
    if (!_isInitializing) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_isInitializing) {
          _initializeCamera();
        }
      });
    }
  }

  @override
  void didPopNext() {
    super.didPopNext();
    // Force reinitialize when returning to this screen
    _initializeCamera(force: true);
  }

  @override
  void didUpdateWidget(covariant CarCameraScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Force reinitialize when widget is updated
    if (!_isInitializing) {
      _initializeCamera();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Stop native preview before the Activity/engine can detach; otherwise camera
    // frames may hit FlutterRenderer after FlutterJNI is gone (fatal on Android).
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _cameraBloc.add(const DisposeCameraRequested());
      return;
    }
    if (state == AppLifecycleState.resumed && !_isInitializing) {
      // Add delay when app resumes to ensure camera service is ready
      // This is especially important after app is cleared and reopened
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && !_isInitializing) {
          _initializeCamera(force: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _routeObserver?.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _pendingSessionPollTimer?.cancel();
    _cameraBloc.close();
    // Reset preferred orientations when leaving camera screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Handle orientation changes
    final orientation = MediaQuery.of(context).orientation;
    if (_currentOrientation != orientation) {
      // Prevent re-initialization if capturing to avoid crash
      if (_isCapturing) return;

      _currentOrientation = orientation;
      // Reinitialize camera when orientation changes
      if (!_isInitializing) {
        _initializeCamera(force: true);
      }
    }
  }

  void _initializeCamera({bool force = false}) {
    // Prevent multiple simultaneous initializations, even for force requests
    if (_isInitializing) return;

    _isInitializing = true;
    if (force) {
      // Force reinitialization by disposing existing controller first
      _cameraBloc.add(const ForceReinitializeCameraRequested());
    } else {
      _cameraBloc.add(const InitializeCameraRequested());
    }

    // Reset flag after a delay to allow for proper reinitialization
    // Increased timeout to accommodate retry logic in the bloc
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _isInitializing = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions and orientation for potential future use
    // final screenHeight = MediaQuery.of(context).size.height;
    // final screenWidth = MediaQuery.of(context).size.width;
    // final orientation = MediaQuery.of(context).orientation;

    Widget cameraContent = BlocProvider<CarCameraBloc>.value(
      value: _cameraBloc,
      child: BlocListener<CarCameraBloc, CarCameraState>(
        listener: (context, state) {
          if (state is CarCameraValidationSuccess) {
            // Stop camera before leaving the route so native frames cannot hit
            // FlutterRenderer after the surface/engine tears down.
            context.read<CarCameraBloc>().add(const DisposeCameraRequested());
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PreviewCarScreen(
                  imagePath: state.imagePath,
                  sessionId: widget.sessionId,
                  isReparking: widget.isReparking,
                  cardNumber: widget.cardNumber,
                ),
              ),
            );
          } else if (state is CarCameraValidationError) {
            // Show error message at bottom of screen
            SnackBars.showErrorSnackBar(
              context,
              state.message,
            );
            // Reset validation state so user can try again
            context.read<CarCameraBloc>().add(const ValidationReset());
          } else if (state is CarCameraInitializationError) {
            // Show camera initialization error
            SnackBars.showErrorSnackBar(
              context,
              state.message,
            );
          } else if (state is CarCameraInitial) {
            // Reset initialization flag when state is reset
            _isInitializing = false;
          }
        },
        child: BlocBuilder<CarCameraBloc, CarCameraState>(
          builder: (context, state) {
            final isCameraInitialized = state is CarCameraInitialized ||
                state is CarCameraValidationError ||
                state is CarCameraFlashToggled;
            final cameraController = state is CarCameraInitialized
                ? state.cameraController
                : state is CarCameraValidationError
                    ? state.cameraController
                    : state is CarCameraFlashToggled
                        ? state.cameraController
                        : null;
            final isFlashOn = state is CarCameraInitialized
                ? state.isFlashOn
                : state is CarCameraValidationError
                    ? state.isFlashOn
                    : state is CarCameraFlashToggled
                        ? state.isFlashOn
                        : false;

            return ScaffoldMessenger(
              child: Scaffold(
                backgroundColor: AppColors.black,
                appBar: const CustomAppBar(showOverflowMenu: true),
                body: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate approximate input container height based on its content
                    final screenHeight = MediaQuery.of(context).size.height;
                    // Container padding (vertical): 0.015 * 2 = 0.03
                    // Header text: ~0.04, Spacing: 0.008, Input field: 0.06, Spacing: 0.01, Button: 0.035
                    // Total: ~0.183 or 18.3%, using 19% for better alignment
                    final estimatedInputHeight = screenHeight * 0.19;

                    return Stack(
                      children: [
                        // Camera Preview Widget (positioned at bottom)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          top:
                              estimatedInputHeight, // Start right after input container
                          child: CameraPreviewWidget(
                            isCameraInitialized: isCameraInitialized,
                            cameraController: cameraController,
                          ),
                        ),

                        // Top Overlay (Flash button, Instructions) - positioned over camera
                        CameraTopOverlay(
                          isFlashOn: isFlashOn,
                          onFlashToggle: () => context
                              .read<CarCameraBloc>()
                              .add(const ToggleFlashRequested()),
                          topOffset:
                              estimatedInputHeight, // Start at camera area
                        ),

                        // Capture Button Overlay (positioned over camera)
                        Positioned(
                          bottom: MediaQuery.of(context).size.width *
                              0.1, // Position at bottom with some margin
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Builder(
                              builder: (builderContext) => GestureDetector(
                                onTap: () {
                                  _capturePhoto(builderContext);
                                },
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.18,
                                  height:
                                      MediaQuery.of(context).size.width * 0.18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                    border: Border.all(
                                      color: AppColors.white,
                                      width: 4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Top Overlay (Input field only)
                        CameraBottomOverlay(
                          onCapture: _capturePhoto,
                          onSubmit: _handleSubmitWithParkingLocation,
                          positionAtTop: true,
                          initialParkingLocation: widget.initialParkingLocation,
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );

    // Wrap with PopScope to prevent back navigation if needed
    if (widget.preventBackNavigation) {
      return PopScope(
        canPop: false, // Prevent back button from navigating back
        child: cameraContent,
      );
    }

    return cameraContent;
  }

  Future<void> _capturePhoto(BuildContext blocContext) async {
    final state = blocContext.read<CarCameraBloc>().state;
    if (state is! CarCameraInitialized && state is! CarCameraFlashToggled) {
      SnackBars.showErrorSnackBar(
        blocContext,
        TextConstants.cameraNotReady,
      );
      return;
    }

    // specific prevention for capture
    if (_isCapturing) return;

    try {
      _isCapturing = true;
      final cameraController = state is CarCameraInitialized
          ? state.cameraController
          : (state as CarCameraFlashToggled).cameraController;
      final isFlashOn = state is CarCameraInitialized
          ? state.isFlashOn
          : (state as CarCameraFlashToggled).isFlashOn;

      // Ensure the camera is initialized
      if (!cameraController.value.isInitialized) {
        SnackBars.showErrorSnackBar(
          blocContext,
          TextConstants.cameraNotReady,
        );
        return;
      }

      // Set flash mode for the photo capture
      await cameraController.setFlashMode(
        isFlashOn ? FlashMode.always : FlashMode.off,
      );

      // Take the picture
      final image = await cameraController.takePicture();

      // Restore flash mode for preview (torch for continuous flash, off for no flash)
      if (cameraController.value.isInitialized) {
        await cameraController.setFlashMode(
          isFlashOn ? FlashMode.torch : FlashMode.off,
        );
      }

      // Reset camera state before navigating
      blocContext.read<CarCameraBloc>().add(const ValidationReset());

      // Trigger validation in background
      if (mounted) {
        blocContext.read<CarCameraBloc>().add(
              ValidateImageRequested(image.path),
            );
      }
    } catch (e) {
      if (mounted) {
        SnackBars.showErrorSnackBar(
          blocContext,
          '${TextConstants.errorCapturingPhoto}: $e',
        );
      }
    } finally {
      _isCapturing = false;
    }
  }

  Future<void> _handleSubmitWithParkingLocation(
    BuildContext context,
    String parkingLocation,
  ) async {
    final state = context.read<CarCameraBloc>().state;
    if (state is! CarCameraInitialized && state is! CarCameraFlashToggled) {
      SnackBars.showErrorSnackBar(
        context,
        TextConstants.cameraNotReady,
      );
      return;
    }

    if (_isCapturing) return;

    try {
      _isCapturing = true;
      final cameraController = state is CarCameraInitialized
          ? state.cameraController
          : (state as CarCameraFlashToggled).cameraController;
      final isFlashOn = state is CarCameraInitialized
          ? state.isFlashOn
          : (state as CarCameraFlashToggled).isFlashOn;

      // Ensure the camera is initialized
      if (!cameraController.value.isInitialized) {
        SnackBars.showErrorSnackBar(
          context,
          TextConstants.cameraNotReady,
        );
        return;
      }

      // Set flash mode for the photo capture
      await cameraController.setFlashMode(
        isFlashOn ? FlashMode.always : FlashMode.off,
      );

      // Take the picture
      final image = await cameraController.takePicture();

      // Restore flash mode for preview
      if (cameraController.value.isInitialized) {
        await cameraController.setFlashMode(
          isFlashOn ? FlashMode.torch : FlashMode.off,
        );
      }

      // Navigate directly to preview screen with parking location
      if (mounted) {
        context.read<CarCameraBloc>().add(const DisposeCameraRequested());
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PreviewCarScreen(
              imagePath: image.path,
              sessionId: widget.sessionId,
              isReparking: widget.isReparking,
              parkingLocation: parkingLocation,
              cardNumber: widget.cardNumber,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBars.showErrorSnackBar(
          context,
          '${TextConstants.errorCapturingPhoto}: $e',
        );
      }
    } finally {
      if (mounted) {
        _isCapturing = false;
      }
    }
  }
}
