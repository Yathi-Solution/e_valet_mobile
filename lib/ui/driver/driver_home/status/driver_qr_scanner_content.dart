import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lottie/lottie.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text_field.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/bloc/connectivity/connectivity_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/connectivity/connectivity_state.dart';
import 'package:niloufer_valet_mobile/bloc/qr/qr_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/qr/qr_event.dart';
import 'package:niloufer_valet_mobile/bloc/qr/qr_state.dart';
import 'package:niloufer_valet_mobile/bloc/driver/tag_submission/tag_submission_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/driver/tag_submission/tag_submission_event.dart';
import 'package:niloufer_valet_mobile/bloc/driver/tag_submission/tag_submission_state.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_status/driver_status_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_status/driver_status_state.dart';
import 'package:niloufer_valet_mobile/services/oauth/session_manager.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';
import 'package:niloufer_valet_mobile/services/offline_sync/parked_card_availability_service.dart';
import 'package:niloufer_valet_mobile/ui/driver/qr_reader/qr_reader_widget.dart';
import 'package:niloufer_valet_mobile/ui/driver/driver_home/status/car_photo_intro_screen.dart';
import 'package:niloufer_valet_mobile/ui/driver/driver_home/status/tab_chip.dart';

class DriverQrScannerContent extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;
  final bool isTablet;
  final bool isDesktop;

  /// Called when user returns from Car Camera screen so parent can show home (two cards) again.
  final VoidCallback? onReturnFromCarCamera;

  const DriverQrScannerContent({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.isTablet,
    required this.isDesktop,
    this.onReturnFromCarCamera,
  });

  @override
  State<DriverQrScannerContent> createState() => _DriverQrScannerContentState();
}

class _DriverQrScannerContentState extends State<DriverQrScannerContent> {
  final TextEditingController _tagNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool get _canSubmitTagNumber => _tagNumberController.text.trim().isNotEmpty;

  /// 0 = Scan (camera), 1 = Type ID Number (form). Default 0 so QR Scan is pre-selected.
  int _selectedTab = 0;
  bool _showCamera =
      false; // true after 2 sec Lottie intro when on Scan tab (or immediately if intro already shown)
  Timer? _introTimer;

  /// Until true, we have not yet checked session — avoid showing Lottie before we know if we should skip it.
  bool _scanIntroChecked = false;

  /// True after the 2s QR Lottie has been shown once; then we skip it when switching back from Type ID to Scan.
  bool _hasShownScanIntroOnce = false;

  /// Set when submitting so third screen knows whether to show parking location form (tag) or go straight to Lottie (QR).
  bool _lastSubmissionWasTagNumber = false;
  String? _lastSubmittedCardNumber;

  /// Holds the driver card ownership mismatch error to show inline right above the Submit button
  /// (in addition to the bottom snackbar). Cleared on input change, tab switch, fresh QR scan, or success path.
  String? _cardValidationError;

  @override
  void initState() {
    super.initState();
    _tagNumberController.addListener(_onTagFormChanged);
    // Show Scan intro (Lottie → camera) only once per login session; when user comes back
    // (same session) we skip the animation and show the camera directly. Flags are cleared on logout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _selectedTab != 0) return;
      _initScanIntro();
    });
  }

  Future<void> _initScanIntro() async {
    final alreadyShown = await SessionManager.hasShownScannerIntroThisSession();
    if (!mounted) return;
    setState(() => _scanIntroChecked = true);
    if (!mounted) return;
    if (alreadyShown) {
      setState(() {
        _hasShownScanIntroOnce = true;
        _showCamera = true;
      });
      return;
    }
    await _startScanIntroTimer();
  }

  void _onTagFormChanged() {
    if (mounted) {
      setState(() {
        _cardValidationError = null;
      });
    }
  }

  void _clearCardValidationError() {
    if (_cardValidationError != null && mounted) {
      setState(() => _cardValidationError = null);
    }
  }

  Future<void> _startScanIntroTimer() async {
    _introTimer?.cancel();
    _hasShownScanIntroOnce =
        true; // so switching back from Type ID to Scan skips intro
    if (!mounted) return;
    setState(() => _showCamera = false);
    // Mark intro as shown immediately so it is only visible once per login even if user leaves before 2s.
    // Await so the flag is persisted before any navigation; otherwise the animation can show again on return.
    await SessionManager.markScannerIntroShown();
    if (!mounted) return;
    _introTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showCamera = true);
    });
  }

  void _onSelectScanTab(BuildContext? blocContext) {
    if (_selectedTab == 0) return;
    blocContext?.read<QrBloc>().add(const QrCameraActivateRequested());
    _clearCardValidationError();
    setState(() {
      _selectedTab = 0;
      if (_scanIntroChecked && _hasShownScanIntroOnce) {
        _introTimer?.cancel();
        _showCamera = true;
      } else if (_scanIntroChecked) {
        // Intro not shown yet this session (e.g. user switched to Type ID before intro finished).
        _startScanIntroTimer();
      }
      // If !_scanIntroChecked, _initScanIntro will run and handle showCamera
    });
  }

  void _onSelectTypeIdTab(BuildContext? blocContext) {
    blocContext?.read<QrBloc>().add(const QrResetRequested());
    _introTimer?.cancel();
    _clearCardValidationError();
    setState(() {
      _selectedTab = 1;
      _showCamera = false;
    });
  }

  @override
  void dispose() {
    _introTimer?.cancel();
    _tagNumberController.removeListener(_onTagFormChanged);
    _tagNumberController.dispose();
    super.dispose();
  }

  void _showCardValidationError(BuildContext context, String message) {
    setState(() => _cardValidationError = message);
  }

  Future<void> _handleSubmit(BuildContext submitContext) async {
    final qrState = submitContext.read<QrBloc>().state;

    int? cardNumber;
    if (qrState.qrData != null) {
      cardNumber = qrState.qrData!.cardNumber;
    } else if (_formKey.currentState?.validate() ?? false) {
      final tagNumber = _tagNumberController.text.trim();
      cardNumber = int.tryParse(tagNumber);
      if (cardNumber == null) {
        _clearCardValidationError();
        SnackBars.showErrorSnackBar(
          submitContext,
          submitContext
              .read<AppTranslationsNotifier>()
              .get(TextConstants.validationEnterValidTagNumber),
        );
        return;
      }
    }

    if (cardNumber != null) {
      if (!TokenStorage.isDriverAssignedCardsLoadedSync()) {
        final t = submitContext.read<AppTranslationsNotifier>();
        final msg = t.get(TextConstants.driverCardsLoading);
        _showCardValidationError(
          submitContext,
          msg.isNotEmpty ? msg : TextConstants.driverCardsLoading,
        );
        return;
      }

      if (!TokenStorage.isDriverCardNumberAllowedSync(cardNumber)) {
        final t = submitContext.read<AppTranslationsNotifier>();
        final msg = t.get(TextConstants.driverCardNotAssigned);
        final baseMsg =
            msg.isNotEmpty ? msg : TextConstants.driverCardNotAssigned;
        final errorMsg = '$baseMsg Please contact Operator.';

        _showCardValidationError(submitContext, errorMsg);
        return;
      }

      final connectivityState = submitContext.read<ConnectivityBloc>().state;
      final isOffline = connectivityState is! ConnectivityOnline;
      if (isOffline &&
          await ParkedCardAvailabilityService.isCardNumberAlreadyInUse(
            cardNumber,
          )) {
        final t = submitContext.read<AppTranslationsNotifier>();
        _showCardValidationError(
          submitContext,
          t.get(TextConstants.tagSubmissionError),
        );
        return;
      }
    }

    _clearCardValidationError();

    if (qrState.qrData != null) {
      _lastSubmissionWasTagNumber = false;
      _lastSubmittedCardNumber = qrState.qrData!.cardNumber.toString();
      submitContext.read<TagSubmissionBloc>().add(
            QrCodeSubmitted(qrState.qrData!),
          );
      return;
    }
    if (cardNumber != null) {
      _lastSubmissionWasTagNumber = true;
      _lastSubmittedCardNumber = cardNumber.toString();
      final statusState = submitContext.read<DriverStatusBloc>().state;
      int outletId = int.tryParse(dotenv.env['OUTLET_ID'] ?? '1') ?? 1;
      if (statusState is DriverStatusLoaded) {
        outletId = statusState.status.outletId;
      }
      submitContext.read<TagSubmissionBloc>().add(
            TagNumberSubmitted(outletId: outletId, cardNumber: cardNumber),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return BlocProvider(
      create: (_) => QrBloc(),
      child: MultiBlocListener(
        listeners: [
          // No auto-submit: when QR is scanned, Submit button is enabled; user taps it manually
          BlocListener<TagSubmissionBloc, TagSubmissionState>(
            listener: (context, submissionState) {
              if (submissionState is TagSubmissionSuccess) {
                _clearCardValidationError();
                context.read<QrBloc>().add(const QrResetRequested());
                // Third screen: parking location form (if tag) or Carphoto.json 2s, then camera
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CarPhotoIntroScreen(
                      cameViaTagNumber: _lastSubmissionWasTagNumber,
                      cardNumber: _lastSubmittedCardNumber,
                      onReturnFromCamera: () {
                        widget.onReturnFromCarCamera?.call();
                        if (mounted) {
                          _introTimer?.cancel();
                          setState(() => _showCamera = true);
                        }
                        context
                            .read<QrBloc>()
                            .add(const QrCameraActivateRequested());
                      },
                    ),
                  ),
                ).then((_) {
                  // When user returns from third screen: show camera again (intro already shown)
                  widget.onReturnFromCarCamera?.call();
                  if (mounted) {
                    _introTimer?.cancel();
                    setState(() => _showCamera = true);
                  }
                  context.read<QrBloc>().add(const QrCameraActivateRequested());
                });
              } else if (submissionState is TagSubmissionError) {
                _showCardValidationError(
                  context,
                  t.get(submissionState.message),
                );
              }
            },
          ),
          BlocListener<QrBloc, QrState>(
            listener: (context, qrState) {
              if (qrState.qrData != null) {
                _clearCardValidationError();
              }
            },
          ),
        ],
        child: Builder(
          builder: (blocContext) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // White header with title and short hint
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: widget.screenHeight * 0.012,
                    horizontal: widget.screenWidth * 0.04,
                  ),
                  color: AppColors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextComponent(
                        labelText: t.getByKey('vehicleDetailsTitle',
                            TextConstants.vehicleDetailsTitle),
                        fontSize: MediaQuery.of(context).size.width * 0.045,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                      SizedBox(height: widget.screenHeight * 0.006),
                      TextComponent(
                        labelText: t.getByKey('vehicleDetailsHint',
                            TextConstants.vehicleDetailsHint),
                        fontSize: widget.screenWidth * 0.032,
                        color: AppColors.black,
                        fontWeight: FontWeight.w400,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: widget.screenHeight * 0.016),
                // Tabs: Scan (default) | Type ID Number
                _buildTabs(t, blocContext),
                SizedBox(height: widget.screenHeight * 0.018),
                Expanded(
                  child: _selectedTab == 0
                      ? _buildScanContent(t)
                      : _buildTypeIdContent(t),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabs(AppTranslationsNotifier t, BuildContext blocContext) {
    final w = widget.screenWidth;
    final isTypeId = _selectedTab == 1;
    final isScan = _selectedTab == 0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.02),
      child: Row(
        children: [
          // First tab: Scan (camera initializes only when selected)
          Expanded(
            child: TabChip(
              icon: Icons.qr_code_scanner,
              label: t.getByKey('scanTabLabel', TextConstants.scanTabLabel),
              isActive: isScan,
              onTap: () => _onSelectScanTab(blocContext),
            ),
          ),
          SizedBox(width: w * 0.025),
          // Second tab: Type ID Number (manual entry)
          Expanded(
            child: TabChip(
              icon: Icons.dialpad,
              label: t.get(TextConstants.typeParkingNumberTabLabel),
              isActive: isTypeId,
              onTap: () => _onSelectTypeIdTab(blocContext),
            ),
          ),
        ],
      ),
    );
  }

  /// Scan tab: dark grey container with camera/Lottie; submit button at bottom (same style as Parking Number tab).
  Widget _buildScanContent(AppTranslationsNotifier t) {
    final w = widget.screenWidth;
    final h = widget.screenHeight;

    final padding = w * 0.02;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.mutedText,
        borderRadius: BorderRadius.circular(w * 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final innerW = (constraints.maxWidth - 2 * padding)
                    .clamp(0.0, double.infinity);
                final innerH = (constraints.maxHeight - 2 * padding)
                    .clamp(0.0, double.infinity);
                return Padding(
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
                    child: !_scanIntroChecked
                        ? const Center(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _showCamera
                            ? QrReaderWidget(
                                screenWidth: widget.screenWidth,
                                screenHeight: widget.screenHeight,
                                isTablet: widget.isTablet,
                                isDesktop: widget.isDesktop,
                                fillWidth: innerW,
                                fillHeight: innerH,
                              )
                            : Lottie.asset(
                                'assets/jsons/QRScan.json',
                                fit: BoxFit.contain,
                                repeat: false,
                              ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(w * 0.04, 0, w * 0.04, h * 0.018),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_cardValidationError != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: h * 0.01),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.03,
                        vertical: h * 0.01,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(w * 0.02),
                      ),
                      child: TextComponent(
                        labelText: _cardValidationError!,
                        color: AppColors.error,
                        fontSize: w * 0.035,
                        fontWeight: FontWeight.w600,
                        textAlign: TextAlign.center,
                        maxLines: 4,
                      ),
                    ),
                  ),
                SizedBox(
              height: h * 0.085,
              child: BlocBuilder<QrBloc, QrState>(
                buildWhen: (previous, current) =>
                    previous.qrData != current.qrData,
                builder: (context, qrState) {
                  final hasScannedQr = qrState.qrData != null;
                  return BlocBuilder<TagSubmissionBloc, TagSubmissionState>(
                    builder: (context, submissionState) {
                      final isLoading = submissionState is TagSubmissionLoading;
                      final canSubmit = hasScannedQr && !isLoading;
                      final buttonHeight = h * 0.085;
                      final textSize = w * 0.072;
                      return SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed:
                              canSubmit ? () => _handleSubmit(context) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor:
                                AppColors.grey.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(w * 0.025),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextComponent(
                                      labelText: t.getByKey('submitButton',
                                          TextConstants.submitButton),
                                      fontSize: textSize,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.white,
                                    ),
                                    SizedBox(width: w * 0.02),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: AppColors.white,
                                      size: textSize,
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeIdContent(AppTranslationsNotifier t) {
    final w = widget.screenWidth;
    final h = widget.screenHeight;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(w * 0.04),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(w * 0.03),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow10,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextComponent(
                    labelText: t.get(TextConstants.tagNumberLabel),
                    fontSize: w * 0.048,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                  Builder(
                    builder: (ctx) {
                      return TextFieldComponent(
                        labelText: t.get(TextConstants.emptyText),
                        hintText: t.getByKey(
                            'tagNumberHint', TextConstants.tagNumberHint),
                        controller: _tagNumberController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        fontSize: w * 0.044,
                        labelFontSize: w * 0.048,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: w * 0.04, vertical: h * 0.022),
                        onSubmitEditing: () => _handleSubmit(ctx),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return TextConstants.validationEnterTagNumber;
                          }
                          if (int.tryParse(value.trim()) == null) {
                            return TextConstants.validationEnterValidNumber;
                          }
                          return null;
                        },
                        borderRadius: w * 0.03,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: h * 0.028),
          if (_cardValidationError != null)
            Padding(
              padding: EdgeInsets.only(bottom: h * 0.012),
              child: TextComponent(
                labelText: _cardValidationError!,
                color: AppColors.error,
                fontSize: w * 0.035,
                fontWeight: FontWeight.w600,
                textAlign: TextAlign.center,
                maxLines: 4,
              ),
            ),
          SizedBox(height: h * 0.02),
          // Submit button – same styling as preview Done button for consistency
          BlocBuilder<TagSubmissionBloc, TagSubmissionState>(
            builder: (context, submissionState) {
              final isLoading = submissionState is TagSubmissionLoading;
              final canSubmit = _canSubmitTagNumber && !isLoading;
              final buttonHeight = h * 0.085;
              final textSize = w * 0.072;
              return SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: canSubmit ? () => _handleSubmit(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.grey.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(w * 0.025),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextComponent(
                              labelText: t.getByKey(
                                  'submitButton', TextConstants.submitButton),
                              fontSize: textSize,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                            SizedBox(width: w * 0.02),
                            Icon(
                              Icons.arrow_forward,
                              color: AppColors.white,
                              size: textSize,
                            ),
                          ],
                        ),
                ),
              );
            },
          ),
          // Extra bottom space so user can scroll submit button above keyboard
          SizedBox(height: h * 0.12),
        ],
      ),
    );
  }
}
