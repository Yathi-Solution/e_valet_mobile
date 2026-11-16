import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:evalet/services/translations/app_translations_notifier.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/text_constants.dart';
import 'package:evalet/ui/common/widgets/text.dart';

/// Review card for a park entered by parking location: shows the location,
/// card number and vehicle number, with an edit button and a large OK button
/// that fills the rest of the card.
class PreviewLocationReviewCard extends StatelessWidget {
  const PreviewLocationReviewCard({
    super.key,
    required this.parkingLocation,
    required this.cardNumber,
    required this.vehicleNumber,
    required this.isSubmitting,
    required this.onEdit,
    required this.onSubmit,
  });

  final String parkingLocation;
  final String? cardNumber;
  final String? vehicleNumber;
  final bool isSubmitting;
  final VoidCallback onEdit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardNumber = this.cardNumber;
    final vehicleNumber = this.vehicleNumber;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColors.accent,
                    size: screenWidth * 0.05,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  TextComponent(
                    labelText: 'Parking Location',
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ],
              ),
              // Edit Icon Button
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.02),
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
          SizedBox(height: screenHeight * 0.01),
          TextComponent(
            labelText: parkingLocation,
            fontSize: screenWidth * 0.038,
            color: AppColors.black,
          ),
          if (cardNumber != null && cardNumber.trim().isNotEmpty)
            ..._labelledValue(
              icon: Icons.badge,
              label: t.get(TextConstants.cardNumberLabel),
              value: cardNumber,
              screenWidth: screenWidth,
              screenHeight: screenHeight,
            ),
          if (vehicleNumber != null && vehicleNumber.isNotEmpty)
            ..._labelledValue(
              icon: Icons.directions_car,
              label: t.get(TextConstants.vehicleNumberLabel),
              value: vehicleNumber,
              screenWidth: screenWidth,
              screenHeight: screenHeight,
            ),
          // Instruction text below vehicle number (with gap)
          SizedBox(height: screenHeight * 0.025),
          TextComponent(
            labelText:
                t.get(TextConstants.afterVehicleParkedConfirmInstruction),
            fontSize: screenWidth * 0.045,
            color: AppColors.black,
            height: 1.35,
            fontWeight: FontWeight.w500,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.02),
          // OK button expands from here to the bottom of the screen
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.disabledBackground,
                  disabledForegroundColor: AppColors.disabledText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isSubmitting
                    ? SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : TextComponent(
                        labelText: t.get(TextConstants.okButton),
                        fontSize: screenWidth * 0.16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
        ],
      ),
    );
  }

  /// An icon and label on one line with the value underneath.
  List<Widget> _labelledValue({
    required IconData icon,
    required String label,
    required String value,
    required double screenWidth,
    required double screenHeight,
  }) {
    return [
      SizedBox(height: screenHeight * 0.012),
      Row(
        children: [
          Icon(
            icon,
            color: AppColors.accent,
            size: screenWidth * 0.045,
          ),
          SizedBox(width: screenWidth * 0.02),
          TextComponent(
            labelText: label,
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ],
      ),
      SizedBox(height: screenHeight * 0.004),
      TextComponent(
        labelText: value,
        fontSize: screenWidth * 0.038,
        color: AppColors.black,
      ),
    ];
  }
}
