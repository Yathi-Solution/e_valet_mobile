import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/models/driver/session/assigned_session.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/full_image_viewer_dialog.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/vehicle_photo_placeholder.dart';

class CarInformationCard extends StatelessWidget {
  final AssignedSession session;

  /// When true, uses smaller image (e.g. when showing handover buttons).
  final bool compact;

  const CarInformationCard({
    super.key,
    required this.session,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow10,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Details Section (above image) — spacing OUTSIDE via margin
          Container(
            margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            padding: EdgeInsets.symmetric(
              vertical: compact ? screenWidth * 0.03 : screenWidth * 0.04,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge Number
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.directions_car,
                      size: compact ? screenWidth * 0.045 : screenWidth * 0.06,
                      color: AppColors.secondary,
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    TextComponent(
                      labelText: t.get(TextConstants.cardNumber),
                      fontSize:
                          compact ? screenWidth * 0.028 : screenWidth * 0.035,
                      color: AppColors.mutedText,
                    ),
                    Spacer(),
                    TextComponent(
                      labelText: session.cardNumber.toString(),
                      fontSize:
                          compact ? screenWidth * 0.038 : screenWidth * 0.05,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ],
                ),

                SizedBox(
                    height:
                        compact ? screenHeight * 0.01 : screenHeight * 0.02),

                Divider(
                  color: AppColors.greyLight,
                  thickness: 1,
                  height: 1,
                ),
                if (session.parkingLocation.isNotEmpty) ...[
                  SizedBox(height: compact ? 4 : 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: compact ? 16 : 20,
                        color: AppColors.secondary,
                      ),
                      SizedBox(width: compact ? 6 : 8),
                      Expanded(
                        child: TextComponent(
                          labelText: session.parkingLocation.toString(),
                          fontSize: compact
                              ? screenWidth * 0.032
                              : screenWidth * 0.04,
                          color: AppColors.black,
                          maxLines: 2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 8 : 12),
                  Divider(
                    color: AppColors.greyLight,
                    thickness: 1,
                    height: 1,
                  ),
                ],

                SizedBox(
                    height:
                        compact ? screenHeight * 0.01 : screenHeight * 0.02),

                // Parked By
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.badge,
                      size: compact ? screenWidth * 0.045 : screenWidth * 0.06,
                      color: AppColors.secondary,
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    TextComponent(
                      labelText: t.get(TextConstants.parkedByLabel),
                      fontSize:
                          compact ? screenWidth * 0.028 : screenWidth * 0.035,
                      color: AppColors.mutedText,
                    ),
                    if (!compact) SizedBox(height: screenHeight * 0.01),
                    TextComponent(
                      labelText: session.parkedBy?.name ??
                          t.get(TextConstants.unknown),
                      fontSize:
                          compact ? screenWidth * 0.032 : screenWidth * 0.04,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                    Spacer(),
                    // Phone Icon
                    IconButton(
                      padding: compact ? const EdgeInsets.all(4) : null,
                      constraints: compact
                          ? const BoxConstraints(minWidth: 32, minHeight: 32)
                          : null,
                      onPressed: () =>
                          _makePhoneCall(session.parkedBy?.phone ?? ''),
                      icon: Icon(
                        Icons.phone,
                        color: AppColors.secondary,
                        size:
                            compact ? screenWidth * 0.045 : screenWidth * 0.06,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Car Image (below details) — tappable to view full size
          GestureDetector(
            onTap: session.photoUrl != null && session.photoUrl!.isNotEmpty
                ? () => FullImageViewerDialog.show(context, session.photoUrl!)
                : null,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.black,
                  width: 2,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(18),
                ),
                color: AppColors.white,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(18),
                ),
                child: session.photoUrl != null
                    ? Image.network(
                        session.photoUrl!,
                        width: double.infinity,
                        height:
                            compact ? screenWidth * 0.45 : screenWidth * 0.6,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: compact
                                ? screenWidth * 0.45
                                : screenWidth * 0.6,
                            color: AppColors.white,
                            child: Center(
                              child: ColorFiltered(
                                colorFilter: const ColorFilter.matrix([
                                  -1, 0, 0, 0, 255, // Red channel inverted
                                  0, -1, 0, 0, 255, // Green channel inverted
                                  0, 0, -1, 0, 255, // Blue channel inverted
                                  0, 0, 0, 1, 0, // Alpha channel unchanged
                                ]),
                                child: Image.asset(
                                  'assets/images/cars.png',
                                  fit: BoxFit.contain,
                                  width: screenWidth * 0.4,
                                  height: screenHeight * 0.4,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        width: double.infinity,
                        height:
                            compact ? screenWidth * 0.45 : screenWidth * 0.6,
                        color: AppColors.white,
                        child: Center(
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.matrix([
                              -1, 0, 0, 0, 255, // Red channel inverted
                              0, -1, 0, 0, 255, // Green channel inverted
                              0, 0, -1, 0, 255, // Blue channel inverted
                              0, 0, 0, 1, 0, // Alpha channel unchanged
                            ]),
                            child: Image.asset(
                              'assets/images/cars.png',
                              fit: BoxFit.contain,
                              width: screenWidth * 0.4,
                              height: screenHeight * 0.4,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    await FlutterPhoneDirectCaller.callNumber(phoneNumber);
  }
}

/// Image section sized by parent (e.g. 40% of screen). Image fills area; placeholder scales up.
class CarImageSection extends StatelessWidget {
  final AssignedSession session;

  const CarImageSection({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: session.photoUrl != null && session.photoUrl!.isNotEmpty
          ? () => FullImageViewerDialog.show(context, session.photoUrl!)
          : null,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.black, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow10,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: session.photoUrl != null
              ? Image.network(
                  session.photoUrl!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _placeholder(context),
                )
              : _placeholder(context),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return VehiclePhotoPlaceholder(
      caption: TextConstants.tapToCaptureVehiclePhoto,
      minHeight: 120,
    );
  }
}
