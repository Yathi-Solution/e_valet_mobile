import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:evalet/services/qr/valet_qr_scanner_controller_factory.dart';
import 'package:evalet/bloc/qr/qr_bloc.dart';
import 'package:evalet/services/translations/app_translations_notifier.dart';
import 'package:evalet/bloc/qr/qr_event.dart';
import 'package:evalet/bloc/qr/qr_state.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/text_constants.dart';
import 'package:evalet/ui/common/widgets/text.dart';
import 'package:evalet/ui/driver/qr_reader/qr_status_overlay_widget.dart';

class QrReaderWidget extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;
  final bool isTablet;
  final bool isDesktop;

  /// When set, the scanner container fills this width/height (e.g. full container in park flow).
  final double? fillWidth;
  final double? fillHeight;

  const QrReaderWidget({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.isTablet,
    required this.isDesktop,
    this.fillWidth,
    this.fillHeight,
  });

  @override
  State<QrReaderWidget> createState() => _QrReaderWidgetState();
}

class _QrReaderWidgetState extends State<QrReaderWidget>
    with WidgetsBindingObserver, RouteAware {
  MobileScannerController? controller;
  bool _isInitializing = false;
  bool _initialCameraCheckDone = false;
  RouteObserver<ModalRoute>? _routeObserver;

  @override
  void initState() {
    super.initState();
    _routeObserver = RouteObserver<ModalRoute>();
    WidgetsBinding.instance.addObserver(this);
    _initializeController();
  }

  void _checkAndStartCameraForInitialState() {
    // This is called after widget is built to ensure camera starts for initial state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Get current QR state from BLoC
      final qrBloc = context.read<QrBloc>();
      final currentState = qrBloc.state;

      // Use BLoC's decision on whether camera should be active
      if (currentState.cameraShouldBeActive && !_isInitializing) {
        _ensureCameraReady(currentState);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeObserver?.subscribe(this, ModalRoute.of(context)!);
    // Only ensure camera if widget is becoming visible and no QR data exists
    // We'll let the state change handler manage this instead
  }

  @override
  void didPopNext() {
    super.didPopNext();
    // When returning to screen, let state change handler manage camera
    // Don't force camera start here as it might conflict with existing data
  }

  @override
  void didUpdateWidget(covariant QrReaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Widget updated, let state change handler manage camera state
  }

  @override
  void activate() {
    super.activate();
    // Widget reactivated, let state change handler manage camera based on current state
  }

  @override
  void deactivate() {
    // Widget is being deactivated (navigating away)
    // Schedule camera stop for after current frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller?.stop();
    });
    super.deactivate();
  }

  void _ensureCameraReady([QrState? state]) {
    // Only ensure camera is ready if BLoC says camera should be active
    if (!mounted) return;

    // If we have state info, check if camera should be active according to BLoC
    if (state != null && !state.cameraShouldBeActive) return;

    // If already initializing, don't start another initialization
    if (_isInitializing) return;

    _isInitializing = true;

    try {
      if (controller == null) {
        // No controller exists, create one
        _initializeController();
      } else {
        // Controller exists, try to start it
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && controller != null) {
            try {
              controller!.start();
            } catch (e) {
              // If start fails, reinitialize
              _initializeController();
            }
          }
        });
      }
    } finally {
      // Reset flag after a reasonable delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _isInitializing = false;
        }
      });
    }
  }

  void _initializeController({bool force = false}) {
    // Prevent multiple simultaneous initializations
    if (_isInitializing && !force) return;

    _isInitializing = true;

    try {
      // Dispose existing controller if any (always dispose on force, or if controller is null)
      if (force || controller == null) {
        controller?.dispose();
        controller = null;

        // Create new controller
        controller = createValetQrScannerController(autoStart: false);

        // Check current state and start controller if needed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final qrBloc = context.read<QrBloc>();
            final currentState = qrBloc.state;

            // Use BLoC's decision on whether camera should be active
            if (currentState.cameraShouldBeActive) {
              _startControllerWithRetry();
            }
          }
        });
      }
    } finally {
      // Reset flag after a reasonable delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _isInitializing = false;
        }
      });
    }
  }

  void _startControllerWithRetry() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted || controller == null) return;

      try {
        controller!.start();
      } catch (e) {
        // Retry after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && controller != null) {
            try {
              controller!.start();
            } catch (e2) {
              // If still failing, reinitialize
              if (mounted) {
                _initializeController(force: true);
              }
            }
          }
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      // When app resumes, check current state and start camera if needed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final qrBloc = context.read<QrBloc>();
          final currentState = qrBloc.state;

          // Use BLoC's decision on whether camera should be active
          if (currentState.cameraShouldBeActive && !_isInitializing) {
            _ensureCameraReady(currentState);
          }
        }
      });
    } else if (state == AppLifecycleState.paused) {
      // Stop controller when app goes to background
      // Schedule for next frame to avoid setState during lifecycle changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller?.stop();
      });
    } else if (state == AppLifecycleState.inactive) {
      // Stop controller when app becomes inactive
      // Schedule for next frame to avoid setState during lifecycle changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller?.stop();
      });
    }
  }

  @override
  void dispose() {
    _routeObserver?.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    _initialCameraCheckDone = false; // Reset for next initialization
    super.dispose();
  }

  void _handleStateChange(BuildContext context, QrState state) async {
    if (controller == null) {
      // If no controller but camera should be active, initialize it
      if (state.cameraShouldBeActive) {
        _initializeController();
      }
      return;
    }

    try {
      if (state.cameraShouldBeActive) {
        // Camera should be active according to BLoC state
        // Schedule for next frame to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted && controller != null) {
            await controller!.start();
          }
        });
      } else {
        // Camera should be stopped according to BLoC state
        // Schedule for next frame to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted && controller != null) {
            await controller!.stop();
          }
        });
      }
    } catch (e) {
      // If camera operation fails, try to recover based on current state
      if (mounted) {
        _handleCameraError(state);
      }
    }
  }

  void _handleCameraError(QrState state) {
    // Only try to restart camera if BLoC says it should be active
    if (state.cameraShouldBeActive) {
      _ensureCameraReady(state);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    // Ensure initial camera state check is done only once
    if (!_initialCameraCheckDone) {
      _initialCameraCheckDone = true;
      _checkAndStartCameraForInitialState();
    }

    final useFillSize = widget.fillWidth != null && widget.fillHeight != null;
    final scannerContainerWidth =
        useFillSize ? widget.fillWidth! : (widget.screenWidth * 0.85);
    final scannerHeight = useFillSize
        ? widget.fillHeight!
        : (widget.isDesktop
            ? widget.screenHeight * 0.25
            : widget.isTablet
                ? widget.screenHeight * 0.28
                : widget.screenHeight * 0.25);

    final borderWidth = widget.screenWidth * 0.005;
    final borderRadius = widget.screenWidth * 0.03;

    final container = Container(
      width: scannerContainerWidth,
      height: scannerHeight,
      decoration: BoxDecoration(
        color: AppColors.lightBeigeBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: borderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BlocListener<QrBloc, QrState>(
          listener: _handleStateChange,
          child: BlocBuilder<QrBloc, QrState>(
            builder: (context, state) {
              final isProcessing = state.isProcessing;

              // Show loading if controller is not initialized
              if (controller == null) {
                return Container(
                  color: AppColors.black,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                    ),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  final side = math.min(w, h) * 0.88;
                  final scanWindow = Rect.fromCenter(
                    center: Offset(w / 2, h / 2),
                    width: side,
                    height: side,
                  );
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      MobileScanner(
                        controller: controller!,
                        scanWindow: scanWindow,
                        errorBuilder: (context, error, child) {
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (mounted) {
                              _ensureCameraReady();
                            }
                          });
                          return Container(
                            color: AppColors.black,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppColors.white,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  TextComponent(
                                    labelText: t.get(
                                      TextConstants.cameraErrorReinitializing,
                                    ),
                                    color: AppColors.white,
                                    fontSize: widget.screenWidth * 0.04,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        onDetect: (capture) {
                          if (isProcessing || state.shouldStopScanner) return;
                          final List<Barcode> barcodes = capture.barcodes;
                          if (barcodes.isNotEmpty) {
                            final barcode = barcodes.first;
                            final value = barcode.rawValue;
                            if (value != null && value.isNotEmpty) {
                              context.read<QrBloc>().add(QrCodeDetected(value));
                            }
                          }
                        },
                      ),
                      if (isProcessing)
                        Container(
                          color: AppColors.qrProcessingOverlay,
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      if (state.shouldStopScanner &&
                          (state.qrData != null || state.errorMessage != null))
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: QrStatusOverlayWidget(
                            state: state,
                            screenWidth: widget.screenWidth,
                            screenHeight: widget.screenHeight,
                            isTablet: widget.isTablet,
                            isDesktop: widget.isDesktop,
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );

    return useFillSize ? container : Center(child: container);
  }
}
