import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/custom_app_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/footer.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text_field.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';
import 'package:niloufer_valet_mobile/ui/driver/preview_car/preview_Car_widgets/preview_header.dart';
import 'package:niloufer_valet_mobile/ui/driver/preview_car/preview_Car_widgets/preview_image_card.dart';
import 'package:niloufer_valet_mobile/ui/driver/preview_car/preview_Car_widgets/preview_submit_button.dart';
import 'package:niloufer_valet_mobile/ui/driver/car_Camera/car_Success.dart';
import 'package:niloufer_valet_mobile/api/driver/sessions_pending_api.dart';
import 'package:niloufer_valet_mobile/models/driver/session/pending_sessions_response.dart';
import 'package:niloufer_valet_mobile/ui/driver/driver_home/driver_home.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_home/driver_menu_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_home/driver_menu_event.dart';
import 'package:niloufer_valet_mobile/bloc/driver/preview_car/preview_car_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/driver/preview_car/preview_car_event.dart';
import 'package:niloufer_valet_mobile/bloc/driver/preview_car/preview_car_state.dart';
import 'package:niloufer_valet_mobile/services/location/location_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/services/offline_sync/offline_parking_service.dart';

class PreviewCarScreen extends StatefulWidget {
  /// Photo path when coming from Scan; null when coming from Type Parking Number only.
  final String? imagePath;
  final String? sessionId;
  final bool isReparking;
  final String? parkingLocation;
  final String? vehicleNumber;
  final String? cardNumber;

  const PreviewCarScreen({
    super.key,
    this.imagePath,
    this.sessionId,
    this.isReparking = false,
    this.parkingLocation,
    this.vehicleNumber,
    this.cardNumber,
  });

  @override
  State<PreviewCarScreen> createState() => _PreviewCarScreenState();
}

class _PreviewCarScreenState extends State<PreviewCarScreen> {
  String? _currentParkingLocation;
  String? _currentVehicleNumber;

  /// Parking location input when in photo flow (captured image); required before Done.
  late final TextEditingController _parkingLocationController;

  /// Prevents multiple rapid taps from triggering duplicate submissions
  bool _isProcessing = false;

  bool _hasNavigatedAfterSuccess = false;

  @override
  void initState() {
    super.initState();
    // Clear any global "no internet" banner so it never shows over the preview
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).clearMaterialBanners();
    });
    _currentParkingLocation = widget.parkingLocation;
    _currentVehicleNumber = widget.vehicleNumber;
    _parkingLocationController = TextEditingController(
      text: widget.parkingLocation ?? '',
    );
    _parkingLocationController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _parkingLocationController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(BuildContext context) async {
    // Guard: prevent multiple rapid taps immediately
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // Get current GPS location
      final coordinates = await LocationService.getCurrentCoordinates();

      if (!context.mounted) return;

      // Use controller text for parking location when in photo flow
      final parkingLocation = _parkingLocationController.text.trim().isNotEmpty
          ? _parkingLocationController.text.trim()
          : _currentParkingLocation;

      final sessionId = widget.sessionId;
      final parsedCardNumber = int.tryParse(widget.cardNumber?.trim() ?? '');
      final cardNumber = parsedCardNumber ??
          OfflineParkingService.cardNumberFromOfflineSessionId(sessionId);
      final checkinSubmittedOnServer = sessionId != null &&
          sessionId.isNotEmpty &&
          !OfflineParkingService.isOfflineSessionId(sessionId);

      context.read<PreviewCarBloc>().add(
            SubmitPhotoRequested(
              imagePath: (widget.parkingLocation == null ||
                      widget.parkingLocation!.isEmpty)
                  ? widget.imagePath
                  : null,
              sessionId: sessionId,
              isReparking: widget.isReparking,
              latitude: coordinates['latitude']!,
              longitude: coordinates['longitude']!,
              accuracy: coordinates['accuracy'],
              parkingLocation: parkingLocation,
              vehicleNumber: _currentVehicleNumber,
              cardNumber: cardNumber,
              checkinSubmittedOnServer: checkinSubmittedOnServer,
            ),
          );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      setState(() => _isProcessing = false);
      SnackBars.showErrorSnackBar(context, e.message);
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _isProcessing = false);
      SnackBars.showErrorSnackBar(
        context,
        'Failed to get location. Please try again.',
      );
    }
  }

  void _refreshParkedCarsCount(BuildContext context) {
    try {
      context.read<DriverMenuBloc>().add(const DriverPendingSessionsRefresh());
    } catch (_) {}
  }

  Future<void> _handlePostParkNavigation(BuildContext context) async {
    if (_hasNavigatedAfterSuccess) return;
    _hasNavigatedAfterSuccess = true;

    _refreshParkedCarsCount(context);

    PendingSessionsResponse? pending;
    try {
      pending = await SessionsPendingApiService.getPendingSessions();
    } catch (_) {
      pending = null;
    }

    if (!context.mounted) return;

    final hasPending = pending != null && pending.sessions.isNotEmpty;

    if (hasPending) {
      try {
        await TokenStorage.clearSessionId();
        await TokenStorage.clearSessionIdFromGetApi();
      } catch (_) {}

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
        (route) => false,
      );
      return;
    }

    final isLocationBased =
        widget.parkingLocation != null && widget.parkingLocation!.isNotEmpty;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CarSuccessScreen(
          imagePath: isLocationBased ? null : widget.imagePath,
          isLocationBasedParking: isLocationBased,
        ),
      ),
    );
  }

  void _showEditDetailsDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final locationController = TextEditingController(
      text: _currentParkingLocation ?? '',
    );
    final vehicleController = TextEditingController(
      text: _currentVehicleNumber ?? '',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final t = context.watch<AppTranslationsNotifier>();
        return AlertDialog(
          title: TextComponent(
            labelText: t.get(TextConstants.editDetails),
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.w600,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextComponent(
                  labelText: t.getByKey('parkingLocationLabel',
                      TextConstants.parkingLocationLabel),
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                SizedBox(height: 6),
                TextField(
                  controller: locationController,
                  autofocus: true,
                  style: TextStyle(fontSize: screenWidth * 0.04),
                  decoration: InputDecoration(
                    hintText: t.getByKey('parkingLocationHint',
                        TextConstants.parkingLocationHint),
                    hintStyle: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: screenWidth * 0.04,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.surfaceBorder,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.accent,
                        width: 2,
                      ),
                    ),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                TextComponent(
                  labelText: t.get(TextConstants.vehicleNumberLabel),
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                SizedBox(height: 6),
                TextField(
                  controller: vehicleController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  style: TextStyle(fontSize: screenWidth * 0.04),
                  decoration: InputDecoration(
                    hintText: t.get(TextConstants.enterVehicleNumberHint),
                    hintStyle: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: screenWidth * 0.04,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.surfaceBorder,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.accent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: TextComponent(
                labelText: t.get(TextConstants.cancel),
                fontSize: screenWidth * 0.038,
                color: AppColors.mutedText,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newLocation = locationController.text.trim();
                final newVehicle = vehicleController.text.trim();
                if (newLocation.isNotEmpty) {
                  setState(() {
                    _currentParkingLocation = newLocation;
                    _currentVehicleNumber =
                        newVehicle.isEmpty ? null : newVehicle;
                  });
                  Navigator.of(context).pop();
                } else {
                  SnackBars.showErrorSnackBar(
                    context,
                    t.get(TextConstants.parkingLocationCannotBeEmpty),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: TextComponent(
                labelText: t.get(TextConstants.saveButton),
                fontSize: screenWidth * 0.038,
                color: AppColors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return BlocProvider(
      create: (context) => PreviewCarBloc(),
      child: BlocListener<PreviewCarBloc, PreviewCarState>(
        listener: (context, state) {
          if (state is PreviewCarSuccess) {
            _handlePostParkNavigation(context);
          } else if (state is PreviewCarError) {
            setState(() => _isProcessing = false);
            SnackBars.showErrorSnackBar(
              context,
              state.message,
            );
          }
        },
        child: BlocBuilder<PreviewCarBloc, PreviewCarState>(
          builder: (context, state) {
            final t = context.watch<AppTranslationsNotifier>();
            final isSubmitting = state is PreviewCarSubmitting || _isProcessing;

            final horizontalPadding = screenWidth * 0.04;
            final isReviewEntry = widget.parkingLocation != null &&
                widget.parkingLocation!.isNotEmpty;
            final isPhotoFlow = (widget.parkingLocation == null ||
                    widget.parkingLocation!.isEmpty) &&
                widget.imagePath != null &&
                widget.imagePath!.isNotEmpty;
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return PopScope(
              canPop: false,
              child: ScaffoldMessenger(
                child: Scaffold(
                  backgroundColor: AppColors.lightBeigeBackground,
                  appBar: const CustomAppBar(showOverflowMenu: true),
                  resizeToAvoidBottomInset: true,
                  body: isPhotoFlow
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: EdgeInsets.only(
                                  left: horizontalPadding,
                                  right: horizontalPadding,
                                  top: horizontalPadding,
                                  bottom: horizontalPadding + bottomInset + 24,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    PreviewHeader(
                                        isReparking: widget.isReparking,
                                        cardNumber: widget.cardNumber,
                                      ),
                                    SizedBox(height: screenHeight * 0.02),
                                    PreviewImageCard(
                                      imagePath: widget.imagePath!,
                                      onRetake: () => Navigator.pop(context),
                                    ),
                                    SizedBox(height: screenHeight * 0.02),
                                    Container(
                                      width: double.infinity,
                                      padding:
                                          EdgeInsets.all(screenWidth * 0.04),
                                      decoration: BoxDecoration(
                                        color: AppColors.cardBackground,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.accent,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: TextFieldComponent(
                                        labelText: t.getByKey(
                                            'parkingLocationLabel',
                                            TextConstants.parkingLocationLabel),
                                        hintText: t.getByKey(
                                            'parkingLocationHint',
                                            TextConstants.parkingLocationHint),
                                        controller: _parkingLocationController,
                                        keyboardType: TextInputType.text,
                                        textInputAction: TextInputAction.done,
                                        fontSize: screenWidth * 0.04,
                                        labelFontSize: 13,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.04,
                                          vertical: screenHeight * 0.018,
                                        ),
                                        borderRadius: 8,
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.02),
                                    PreviewSubmitButton(
                                      onSubmit: () => _handleSubmit(context),
                                      isReparking: widget.isReparking,
                                      isLoading: isSubmitting,
                                      isEnabled: _parkingLocationController.text
                                          .trim()
                                          .isNotEmpty,
                                      overrideLabel: t.getByKey(
                                          'previewDoneButton',
                                          TextConstants.previewDoneButton),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SafeArea(
                              top: false,
                              child: const Footer(),
                            ),
                          ],
                        )
                      : Stack(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                left: horizontalPadding,
                                right: horizontalPadding,
                                top: horizontalPadding,
                                bottom: isReviewEntry ? 0.0 : horizontalPadding,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  PreviewHeader(
                                    isReparking: widget.isReparking,
                                    cardNumber: widget.cardNumber,
                                  ),
                                  SizedBox(height: screenHeight * 0.02),

                                  // Parking Location Display (if provided) - container expands till bottom of screen, OK button inside at bottom
                                  if (widget.parkingLocation != null &&
                                      widget.parkingLocation!.isNotEmpty)
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        padding:
                                            EdgeInsets.all(screenWidth * 0.04),
                                        decoration: BoxDecoration(
                                          color: AppColors.cardBackground,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.accent,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.location_on,
                                                      color: AppColors.accent,
                                                      size: screenWidth * 0.05,
                                                    ),
                                                    SizedBox(
                                                        width:
                                                            screenWidth * 0.02),
                                                    TextComponent(
                                                      labelText:
                                                          'Parking Location',
                                                      fontSize:
                                                          screenWidth * 0.04,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColors.black,
                                                    ),
                                                  ],
                                                ),
                                                // Edit Icon Button
                                                InkWell(
                                                  onTap: _showEditDetailsDialog,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  child: Container(
                                                    padding: EdgeInsets.all(
                                                        screenWidth * 0.02),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.accentSoft,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.edit,
                                                      color: AppColors.accent,
                                                      size: screenWidth * 0.045,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                                height: screenHeight * 0.01),
                                            TextComponent(
                                              labelText:
                                                  _currentParkingLocation ??
                                                      widget.parkingLocation ??
                                                      '',
                                              fontSize: screenWidth * 0.038,
                                              color: AppColors.black,
                                            ),
                                            if (widget.cardNumber != null &&
                                                widget.cardNumber!
                                                    .trim()
                                                    .isNotEmpty) ...[
                                              SizedBox(
                                                  height: screenHeight * 0.012),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.badge,
                                                    color: AppColors.accent,
                                                    size: screenWidth * 0.045,
                                                  ),
                                                  SizedBox(
                                                      width:
                                                          screenWidth * 0.02),
                                                  TextComponent(
                                                    labelText: t.get(
                                                        TextConstants
                                                            .cardNumberLabel),
                                                    fontSize:
                                                        screenWidth * 0.035,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.black,
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                  height: screenHeight * 0.004),
                                              TextComponent(
                                                labelText: widget.cardNumber!,
                                                fontSize: screenWidth * 0.038,
                                                color: AppColors.black,
                                              ),
                                            ],
                                            if (_currentVehicleNumber != null &&
                                                _currentVehicleNumber!
                                                    .isNotEmpty) ...[
                                              SizedBox(
                                                  height: screenHeight * 0.012),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.directions_car,
                                                    color: AppColors.accent,
                                                    size: screenWidth * 0.045,
                                                  ),
                                                  SizedBox(
                                                      width:
                                                          screenWidth * 0.02),
                                                  TextComponent(
                                                    labelText: t.get(
                                                        TextConstants
                                                            .vehicleNumberLabel),
                                                    fontSize:
                                                        screenWidth * 0.035,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.black,
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                  height: screenHeight * 0.004),
                                              TextComponent(
                                                labelText:
                                                    _currentVehicleNumber!,
                                                fontSize: screenWidth * 0.038,
                                                color: AppColors.black,
                                              ),
                                            ],
                                            // Instruction text below vehicle number (with gap)
                                            SizedBox(
                                                height: screenHeight * 0.025),
                                            TextComponent(
                                              labelText: t.get(TextConstants
                                                  .afterVehicleParkedConfirmInstruction),
                                              fontSize: screenWidth * 0.045,
                                              color: AppColors.black,
                                              height: 1.35,
                                              fontWeight: FontWeight.w500,
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(
                                                height: screenHeight * 0.02),
                                            // OK button expands from here to the bottom of the screen
                                            Expanded(
                                              child: SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  onPressed: isSubmitting
                                                      ? null
                                                      : () => _handleSubmit(
                                                          context),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        AppColors.primary,
                                                    foregroundColor:
                                                        AppColors.white,
                                                    disabledBackgroundColor:
                                                        AppColors
                                                            .disabledBackground,
                                                    disabledForegroundColor:
                                                        AppColors.disabledText,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    elevation: 0,
                                                  ),
                                                  child: isSubmitting
                                                      ? SizedBox(
                                                          width: 32,
                                                          height: 32,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                        Color>(
                                                                    AppColors
                                                                        .white),
                                                          ),
                                                        )
                                                      : TextComponent(
                                                          labelText: t.get(
                                                              TextConstants
                                                                  .okButton),
                                                          fontSize:
                                                              screenWidth *
                                                                  0.16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              AppColors.white,
                                                        ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                                height: screenHeight * 0.02),
                                          ],
                                        ),
                                      ),
                                    ),

                                  // When review entry: container expands to screen bottom only (no footer below)
                                  if (!isReviewEntry) const Spacer(),

                                  // Footer only when NOT review entry (so container can expand till screen bottom)
                                  if (!isReviewEntry) const Footer(),
                                ],
                              ),
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
}
