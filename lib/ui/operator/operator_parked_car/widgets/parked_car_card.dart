import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/key_rack_item.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/full_image_viewer_dialog.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/utils/time_utils.dart';

class ParkedCarCard extends StatelessWidget {
  final KeyRackItem item;
  final VoidCallback? onTap;
  final Function(int cardNumber, String sessionId)? onManualRequest;

  /// When false (e.g. auto mode enabled), manual request button is disabled.
  final bool manualRequestEnabled;

  final bool isHighlighted;

  const ParkedCarCard({
    super.key,
    required this.item,
    this.onTap,
    this.onManualRequest,
    this.manualRequestEnabled = true,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isHighlighted
              ? AppColors.accentSoft
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted
                ? AppColors.accent
                : AppColors.grey.withOpacity(0.2),
            width: isHighlighted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                  ? AppColors.accent.withOpacity(0.2)
                  : AppColors.black.withOpacity(0.08),
              spreadRadius: isHighlighted ? 2 : 0,
              blurRadius: isHighlighted ? 16 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Image (no overlay badge) - tap to view full size
            GestureDetector(
              onTap: item.photoUrl.isNotEmpty
                  ? () => FullImageViewerDialog.show(context, item.photoUrl)
                  : null,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                child: item.photoUrl.isNotEmpty
                    ? Image.network(
                        item.photoUrl,
                        height: screenHeight * 0.08,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage(
                              screenWidth, screenHeight);
                        },
                      )
                    : _buildPlaceholderImage(screenWidth, screenHeight),
              ),
            ),
            // Card Info Section (height fits content)
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.01),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Number (first line)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.credit_card,
                        size: screenWidth * (Platform.isIOS ? 0.016 : 0.018),
                        color: AppColors.primary,
                      ),
                      SizedBox(width: screenWidth * 0.004),
                      Flexible(
                        child: TextComponent(
                          labelText:
                              TextConstants.cardNumberWithHash(item.cardNumber),
                          fontWeight: FontWeight.bold,
                          fontSize:
                              screenWidth * (Platform.isIOS ? 0.018 : 0.02),
                          color: AppColors.black,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.004),
                  // Parked Duration / Time (next line)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: screenWidth * (Platform.isIOS ? 0.016 : 0.018),
                        color: AppColors.primary,
                      ),
                      SizedBox(width: screenWidth * 0.003),
                      Flexible(
                        child: TextComponent(
                          labelText: item.duration,
                          fontSize:
                              screenWidth * (Platform.isIOS ? 0.018 : 0.02),
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.002),
                  // Parking Location (if available)
                  if (item.parkingLocation != null &&
                      item.parkingLocation!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: screenWidth * 0.018,
                          color: AppColors.error,
                        ),
                        SizedBox(width: screenWidth * 0.004),
                        Expanded(
                          child: TextComponent(
                            labelText: item.parkingLocation!,
                            fontSize: screenWidth * 0.02,
                            color: AppColors.black,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.002),
                  ],
                  // Parked By (if available)
                  if (item.parkedByName != null &&
                      item.parkedByName!.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: screenWidth * 0.018,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: screenWidth * 0.004),
                        Expanded(
                          child: TextComponent(
                            labelText: t.get(TextConstants.parkedByWithName(
                                item.parkedByName!)),
                            fontSize: screenWidth * 0.018,
                            color: AppColors.black,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.002),
                  ],
                  // Parked time info (converted to IST)
                  SizedBox(height: screenHeight * 0.002),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: screenWidth * 0.018,
                        color: AppColors.mutedText,
                      ),
                      SizedBox(width: screenWidth * 0.004),
                      Expanded(
                        child: TextComponent(
                          labelText: t.get(TimeUtils.formatUtcToIstFullDateTime(
                              item.parkedAt)),
                          fontSize: screenWidth * 0.015,
                          color: AppColors.mutedText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // Manual Request Button (disabled when auto mode is on)
                  if (onManualRequest != null) ...[
                    SizedBox(height: screenHeight * 0.008),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: manualRequestEnabled
                            ? () => onManualRequest!(
                                  item.cardNumber,
                                  item.sessionId,
                                )
                            : null,
                        label: TextComponent(
                          labelText:
                              t.get(TextConstants.manualRequestButtonLabel),
                          fontSize: screenWidth * 0.015,
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: manualRequestEnabled
                              ? AppColors.primary
                              : AppColors.grey,
                          foregroundColor: AppColors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.008,
                            horizontal: screenWidth * 0.008,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(double screenWidth, double screenHeight) {
    return Container(
      height: screenHeight * 0.08,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.directions_car_rounded,
          size: screenWidth * 0.04,
          color: AppColors.primary.withOpacity(0.5),
        ),
      ),
    );
  }
}
