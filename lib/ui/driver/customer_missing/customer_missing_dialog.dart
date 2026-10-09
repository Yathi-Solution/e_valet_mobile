import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/bloc/driver/initiate_repark/initiate_repark_bloc.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/bloc/driver/initiate_repark/initiate_repark_event.dart';
import 'package:niloufer_valet_mobile/bloc/driver/initiate_repark/initiate_repark_state.dart';
import 'package:niloufer_valet_mobile/services/location/location_service.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/driver/driver_home/status/car_photo_intro_screen.dart';

class CustomerMissingDialog extends StatefulWidget {
  final String sessionId;
  final VoidCallback? onCancel;

  const CustomerMissingDialog({
    super.key,
    required this.sessionId,
    this.onCancel,
  });

  static Future<void> show(
    BuildContext context, {
    required String sessionId,
    VoidCallback? onCancel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BlocProvider(
        create: (context) => InitiateReparkBloc(),
        child: CustomerMissingDialog(
          sessionId: sessionId,
          onCancel: onCancel,
        ),
      ),
    );
  }

  @override
  State<CustomerMissingDialog> createState() => _CustomerMissingDialogState();
}

class _CustomerMissingDialogState extends State<CustomerMissingDialog> {
  /// Prevents multiple rapid taps from triggering duplicate actions
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.06),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Car Icon with Circular Arrow
            Container(
              width: screenWidth * 0.2,
              height: screenWidth * 0.2,
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Car Icon
                  Icon(
                    Icons.directions_car,
                    size: screenWidth * 0.12,
                    color: AppColors.white,
                  ),
                  // Refresh/Repark Icon - positioned at top right
                  Positioned(
                    right: screenWidth * 0.02,
                    top: screenWidth * 0.02,
                    child: Icon(
                      Icons.refresh,
                      size: screenWidth * 0.05,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: screenHeight * 0.03),

            // Main Question
            TextComponent(
              labelText: t.get(TextConstants.reparkConfirmationTitle),
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
              textAlign: TextAlign.center,
            ),

            SizedBox(height: screenHeight * 0.015),

            // Explanatory Text
            TextComponent(
              labelText: t.get(TextConstants.reparkConfirmationMessage),
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w400,
              color: AppColors.mutedText,
              textAlign: TextAlign.center,
            ),

            SizedBox(height: screenHeight * 0.02),

            // Instruction text above proceed button
            TextComponent(
              labelText: t.get(TextConstants.pressBelowToProceedRepark),
              fontSize: screenWidth * 0.038,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
              textAlign: TextAlign.center,
            ),

            SizedBox(height: screenHeight * 0.02),

            // Proceed Button (large)
            BlocConsumer<InitiateReparkBloc, InitiateReparkState>(
              listener: (context, state) {
                if (state is InitiateReparkSuccess) {
                  if (!context.mounted) return;
                  SnackBars.showSuccessSnackBar(
                      context, state.response.message);
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  // Navigate to latest vehicle details screen (Scan / Type Parking Number) for reparking
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    navigator.pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => CarPhotoIntroScreen(
                          cameViaTagNumber: false,
                          sessionId: widget.sessionId,
                          isReparking: true,
                        ),
                      ),
                    );
                  });
                } else if (state is InitiateReparkError) {
                  setState(() => _isProcessing = false);
                  if (context.mounted) {
                    SnackBars.showErrorSnackBar(context, state.message);
                  }
                }
              },
              builder: (context, state) {
                final isLoading =
                    state is InitiateReparkLoading || _isProcessing;
                return SizedBox(
                  width: double.infinity,
                  height: screenHeight * 0.08,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            // Guard: prevent multiple rapid taps immediately
                            if (_isProcessing) return;
                            setState(() => _isProcessing = true);

                            try {
                              // Request location permission if needed
                              LocationPermission permission =
                                  await LocationService.checkPermission();
                              if (permission == LocationPermission.denied) {
                                permission =
                                    await LocationService.requestPermission();
                              }

                              if (permission == LocationPermission.denied ||
                                  permission ==
                                      LocationPermission.deniedForever) {
                                if (!context.mounted) return;
                                setState(() => _isProcessing = false);
                                SnackBars.showErrorSnackBar(
                                  context,
                                  'Location permission is required to initiate repark.',
                                );
                                return;
                              }

                              // Get current location
                              final position =
                                  await LocationService.getCurrentLocation();

                              if (!context.mounted) return;

                              // Trigger the API call
                              context.read<InitiateReparkBloc>().add(
                                    InitiateReparkRequested(
                                      sessionId: widget.sessionId,
                                      latitude: position.latitude,
                                      longitude: position.longitude,
                                      accuracy: position.accuracy,
                                    ),
                                  );
                            } catch (e) {
                              if (!context.mounted) return;
                              setState(() => _isProcessing = false);
                              SnackBars.showErrorSnackBar(
                                context,
                                'Failed to get location: ${getDisplayErrorMessage(e)}',
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.nearBlack,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                      disabledBackgroundColor: AppColors.disabledBackground,
                      disabledForegroundColor: AppColors.disabledText,
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: screenWidth * 0.05,
                            height: screenWidth * 0.05,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.black),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextComponent(
                                labelText: t.get(TextConstants.proceedToRepark),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Icon(
                                Icons.arrow_forward,
                                color: AppColors.white,
                                size: 20,
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),

            SizedBox(height: screenHeight * 0.02),

            // Instruction and Cancel Button
            TextComponent(
              labelText: t.get(TextConstants.pressBelowToCancel),
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedText,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.008),
            BlocBuilder<InitiateReparkBloc, InitiateReparkState>(
              builder: (context, state) {
                final isLoading =
                    state is InitiateReparkLoading || _isProcessing;
                return TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          widget.onCancel?.call();
                        },
                  child: TextComponent(
                    labelText: t.get(TextConstants.cancel),
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w500,
                    color: isLoading ? AppColors.greyLight : AppColors.grey,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
