import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:evalet/services/translations/app_translations_notifier.dart';
import 'package:evalet/ui/common/widgets/custom_app_bar.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/widgets/footer.dart';
import 'package:evalet/ui/common/widgets/text_field.dart';
import 'package:evalet/ui/common/text_constants.dart';
import 'package:evalet/ui/common/widgets/snack_bar.dart';
import 'package:evalet/ui/driver/preview_car/preview_Car_widgets/preview_edit_details_dialog.dart';
import 'package:evalet/ui/driver/preview_car/preview_Car_widgets/preview_header.dart';
import 'package:evalet/ui/driver/preview_car/preview_Car_widgets/preview_image_card.dart';
import 'package:evalet/ui/driver/preview_car/preview_Car_widgets/preview_location_review_card.dart';
import 'package:evalet/ui/driver/preview_car/preview_Car_widgets/preview_submit_button.dart';
import 'package:evalet/ui/driver/car_Camera/car_Success.dart';
import 'package:evalet/api/driver/sessions_pending_api.dart';
import 'package:evalet/ui/driver/driver_home/driver_home.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';
import 'package:evalet/ui/driver/driver_home/park_flow_signals.dart';
import 'package:evalet/bloc/driver/driver_home/driver_menu_bloc.dart';
import 'package:evalet/bloc/driver/driver_home/driver_menu_event.dart';
import 'package:evalet/bloc/driver/preview_car/preview_car_bloc.dart';
import 'package:evalet/bloc/driver/preview_car/preview_car_event.dart';
import 'package:evalet/bloc/driver/preview_car/preview_car_state.dart';
import 'package:evalet/services/location/location_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/services/offline_sync/offline_parking_service.dart';

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

  /// Location lookup started when the screen opens, so the fix is usually
  /// ready by the time the driver taps Done. Resolves to null on failure.
  Future<Map<String, double>?>? _warmCoordinates;

  /// Whether the driver has other checked-in cars still waiting to be parked.
  /// Started alongside the park call so the result is ready when it succeeds.
  Future<bool>? _otherPendingSessions;

  Future<bool> _fetchHasOtherPendingSessions() async {
    try {
      final pending = await SessionsPendingApiService.getPendingSessions()
          .timeout(const Duration(seconds: 4));
      // The session being parked may still be listed; it doesn't count.
      return pending.sessions.any((s) => s.sessionId != widget.sessionId);
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _warmCoordinates = LocationService.getFastCoordinates()
        .then<Map<String, double>?>((c) => c)
        .catchError((_) => null);
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
    ParkFlowSignals.setParkSubmitInProgress(false);
    _parkingLocationController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(BuildContext context) async {
    // Guard: prevent multiple rapid taps immediately
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    // Tell the pending-session watchdogs not to treat this session as cancelled
    // once the park succeeds and it leaves the pending list.
    ParkFlowSignals.setParkSubmitInProgress(true);

    try {
      // Get current GPS location
      // Use the lookup started in initState; retry once if it failed so the
      // driver still sees a proper error (permission, location off, ...).
      final coordinates =
          await _warmCoordinates ?? await LocationService.getFastCoordinates();

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

      _otherPendingSessions = _fetchHasOtherPendingSessions();

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
      ParkFlowSignals.setParkSubmitInProgress(false);
      if (!context.mounted) return;
      setState(() => _isProcessing = false);
      SnackBars.showErrorSnackBar(context, e.message);
    } catch (e) {
      ParkFlowSignals.setParkSubmitInProgress(false);
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

    // The session is parked, so it is no longer pending. Clear the stored id
    // right away; otherwise a watchdog poll sees it missing from the pending
    // list, assumes it was cancelled and pops back to Home before the success
    // screen appears.
    try {
      await TokenStorage.clearSessionId();
      await TokenStorage.clearSessionIdFromGetApi();
    } catch (_) {}
    ParkFlowSignals.setParkSubmitInProgress(false);
    if (!context.mounted) return;

    _refreshParkedCarsCount(context);

    // Usually already resolved: it ran while the park request was uploading.
    final hasPending =
        await (_otherPendingSessions ?? _fetchHasOtherPendingSessions());

    if (!context.mounted) return;

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

  Future<void> _showEditDetailsDialog() async {
    final result = await PreviewEditDetailsDialog.show(
      context,
      parkingLocation: _currentParkingLocation,
      vehicleNumber: _currentVehicleNumber,
    );
    if (result == null || !mounted) return;
    setState(() {
      _currentParkingLocation = result.parkingLocation;
      _currentVehicleNumber = result.vehicleNumber;
    });
  }

  /// True when the driver typed a parking location instead of taking a photo.
  bool get _isReviewEntry =>
      widget.parkingLocation != null && widget.parkingLocation!.isNotEmpty;

  /// True when the driver took a photo and still has to enter the location.
  bool get _isPhotoFlow =>
      !_isReviewEntry &&
      widget.imagePath != null &&
      widget.imagePath!.isNotEmpty;

  void _onPreviewState(BuildContext context, PreviewCarState state) {
    if (state is PreviewCarSuccess) {
      _handlePostParkNavigation(context);
    } else if (state is PreviewCarError) {
      ParkFlowSignals.setParkSubmitInProgress(false);
      setState(() => _isProcessing = false);
      SnackBars.showErrorSnackBar(
        context,
        state.message,
      );
    }
  }

  /// Photo flow: the photo, a parking location field and the Done button.
  Widget _buildPhotoFlowBody(BuildContext context, bool isSubmitting) {
    final t = context.watch<AppTranslationsNotifier>();
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.04;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent,
                      width: 1.5,
                    ),
                  ),
                  child: TextFieldComponent(
                    labelText: t.getByKey('parkingLocationLabel',
                        TextConstants.parkingLocationLabel),
                    hintText: t.getByKey('parkingLocationHint',
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
                  isEnabled: _parkingLocationController.text.trim().isNotEmpty,
                  overrideLabel: t.getByKey(
                      'previewDoneButton', TextConstants.previewDoneButton),
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
    );
  }

  /// Location flow: review the typed details and confirm with OK.
  Widget _buildReviewBody(BuildContext context, bool isSubmitting) {
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = MediaQuery.of(context).size.width * 0.04;
    final isReviewEntry = _isReviewEntry;

    return Stack(
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
              if (isReviewEntry)
                Expanded(
                  child: PreviewLocationReviewCard(
                    parkingLocation:
                        _currentParkingLocation ?? widget.parkingLocation ?? '',
                    cardNumber: widget.cardNumber,
                    vehicleNumber: _currentVehicleNumber,
                    isSubmitting: isSubmitting,
                    onEdit: _showEditDetailsDialog,
                    onSubmit: () => _handleSubmit(context),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PreviewCarBloc(),
      child: BlocListener<PreviewCarBloc, PreviewCarState>(
        listener: _onPreviewState,
        child: BlocBuilder<PreviewCarBloc, PreviewCarState>(
          builder: (context, state) {
            final isSubmitting = state is PreviewCarSubmitting || _isProcessing;

            return PopScope(
              canPop: false,
              child: ScaffoldMessenger(
                child: Scaffold(
                  backgroundColor: AppColors.lightBeigeBackground,
                  appBar: const CustomAppBar(showOverflowMenu: true),
                  resizeToAvoidBottomInset: true,
                  body: _isPhotoFlow
                      ? _buildPhotoFlowBody(context, isSubmitting)
                      : _buildReviewBody(context, isSubmitting),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
