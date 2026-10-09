import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/button_metrics.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/vehicle_photo_placeholder.dart';

class PreviewImageCard extends StatelessWidget {
  final String imagePath;
  final VoidCallback onRetake;

  const PreviewImageCard({
    super.key,
    required this.imagePath,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final screenHeight = MediaQuery.of(context).size.height;
    final file = File(imagePath);
    final fileExists = file.existsSync();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.trackGray, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (fileExists)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                file,
                width: double.infinity,
                height: screenHeight * 0.3,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return VehiclePhotoPlaceholder(
                    caption: t.get(TextConstants.tapToCaptureVehiclePhoto),
                    onTap: onRetake,
                    minHeight: screenHeight * 0.25,
                  );
                },
              ),
            )
          else
            VehiclePhotoPlaceholder(
              caption: t.get(TextConstants.tapToCaptureVehiclePhoto),
              onTap: onRetake,
              minHeight: screenHeight * 0.25,
            ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: ButtonMetrics.retakeWidth(context),
              height: ButtonMetrics.retakeHeight(context),
              child: ElevatedButton.icon(
                onPressed: onRetake,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ButtonMetrics.retakeRadius(context),
                    ),
                  ),
                  elevation: 0,
                ),
                icon: Icon(
                  Icons.camera_alt,
                  size: ButtonMetrics.retakeIconSize(context),
                ),
                label: TextComponent(
                  labelText:
                      t.getByKey('retakeButton', TextConstants.retakeButton),
                  fontSize: ButtonMetrics.retakeFontSize(context),
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
