import 'package:flutter/material.dart';
import 'package:niloufer_valet_mobile/models/driver/parked/my_parked_sessions_response.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/full_image_viewer_dialog.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/utils/time_utils.dart';

class DriverParkedCarCard extends StatelessWidget {
  const DriverParkedCarCard({
    super.key,
    required this.session,
    required this.t,
    required this.onManualRequest,
    this.isProcessing = false,
    this.showManualRequest = true,
  });

  final MyParkedSession session;
  final AppTranslationsNotifier t;
  final VoidCallback? onManualRequest;
  final bool isProcessing;
  final bool showManualRequest;

  @override
  Widget build(BuildContext context) {
    final parkingLocation = session.parkingLocation?.trim() ?? '';
    final vehicleNumber = session.vehicleNumber?.trim() ?? '';
    final duration = session.parkedDuration;
    final sourceLabel = session.isOwn
        ? t.get(TextConstants.driverOwnParkedCarsSection)
        : t.get(TextConstants.driverPassedToMeSection);

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: () {
        final url = session.photoUrl;
        if (url != null && url.isNotEmpty) {
          FullImageViewerDialog.show(context, url);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accent.withOpacity(0.14),
                    AppColors.accent.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  _buildPhotoThumbnail(context),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextComponent(
                          labelText: TextConstants.cardNumberWithHash(
                            session.cardNumber,
                          ),
                          color: AppColors.bodyText,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                        if (duration.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 4),
                              TextComponent(
                                labelText: duration,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: session.isOwn
                          ? AppColors.accentSoft
                          : AppColors.coralLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextComponent(
                      labelText: sourceLabel,
                      color: AppColors.bodyText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (parkingLocation.isNotEmpty)
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      iconColor: AppColors.error,
                      label: t.get(TextConstants.parkingLocationLabel),
                      value: parkingLocation,
                    ),
                  if (vehicleNumber.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.confirmation_number_outlined,
                      iconColor: AppColors.accent,
                      label: t.get(TextConstants.vehicleNumberLabel),
                      value: vehicleNumber,
                    ),
                  ],
                  if (session.parkedAt.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.access_time_rounded,
                      iconColor: AppColors.mutedText,
                      label: t.get(TextConstants.carLogsParkedAt),
                      value: t.get(
                        TimeUtils.formatUtcToIstFullDateTime(session.parkedAt),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (showManualRequest && !session.isPendingLocalSync)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isProcessing ? null : onManualRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.headerDark,
                          foregroundColor: AppColors.textOnDark,
                          disabledBackgroundColor: AppColors.disabledBackground,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.textOnDark,
                                  ),
                                ),
                              )
                            : TextComponent(
                                labelText: t.get(
                                  TextConstants.manualRequestButtonLabel,
                                ),
                                color: AppColors.textOnDark,
                                fontWeight: FontWeight.w600,
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(BuildContext context) {
    final url = session.photoUrl;
    final hasPhoto = session.hasPhotos && url != null && url.isNotEmpty;

    if (!hasPhoto) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.directions_car_rounded,
          color: AppColors.accent,
          size: 28,
        ),
      );
    }

    return GestureDetector(
      onTap: () => FullImageViewerDialog.show(context, url),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            width: 48,
            height: 48,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.directions_car_rounded,
                color: AppColors.accent,
                size: 28,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextComponent(
                labelText: label,
                color: AppColors.mutedText,
                fontSize: 12,
              ),
              const SizedBox(height: 2),
              TextComponent(
                labelText: value,
                color: AppColors.bodyText,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
