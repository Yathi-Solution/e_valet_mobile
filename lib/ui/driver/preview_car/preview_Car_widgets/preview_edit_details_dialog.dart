import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:evalet/services/translations/app_translations_notifier.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/text_constants.dart';
import 'package:evalet/ui/common/widgets/snack_bar.dart';
import 'package:evalet/ui/common/widgets/text.dart';

/// Dialog for correcting the parking location and vehicle number before the
/// park is confirmed.
class PreviewEditDetailsDialog {
  /// Returns the saved values, or null when the driver cancels.
  /// [vehicleNumber] in the result is null when the field was left empty.
  static Future<({String parkingLocation, String? vehicleNumber})?> show(
    BuildContext context, {
    required String? parkingLocation,
    required String? vehicleNumber,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final locationController = TextEditingController(
      text: parkingLocation ?? '',
    );
    final vehicleController = TextEditingController(
      text: vehicleNumber ?? '',
    );

    InputDecoration decoration(String hintText) {
      return InputDecoration(
        hintText: hintText,
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
      );
    }

    return showDialog<({String parkingLocation, String? vehicleNumber})>(
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
                  decoration: decoration(
                    t.getByKey('parkingLocationHint',
                        TextConstants.parkingLocationHint),
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
                  decoration: decoration(
                    t.get(TextConstants.enterVehicleNumberHint),
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
                  Navigator.of(context).pop((
                    parkingLocation: newLocation,
                    vehicleNumber: newVehicle.isEmpty ? null : newVehicle,
                  ));
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
}
