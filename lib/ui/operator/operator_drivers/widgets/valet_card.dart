import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_valet/valet_response.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/skeleton_loader.dart';
import 'package:niloufer_valet_mobile/utils/time_utils.dart';
import 'package:niloufer_valet_mobile/utils/valet_utils.dart';

class ValetCard extends StatelessWidget {
  final ValetResponse? valet;
  final bool isLoading;
  final VoidCallback? onTap;

  /// Logout callback; when set, a Logout button is shown in the card when valet is online (available / on duty / on break). Hidden when offline.
  final void Function(ValetResponse valet)? onLogoutValet;

  const ValetCard({
    super.key,
    this.valet,
    this.isLoading = false,
    this.onTap,
    this.onLogoutValet,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final screenWidth = MediaQuery.of(context).size.width;
    // Larger fonts for clearer visibility in valet details card
    final bodyFontSize = (screenWidth * 0.022).clamp(11.0, 15.0);
    final smallFontSize = (screenWidth * 0.024).clamp(12.0, 15.0);
    final titleFontSize = (screenWidth * 0.032).clamp(14.0, 19.0); // name
    final phoneFontSize =
        (screenWidth * 0.028).clamp(13.0, 17.0); // phone number larger
    const padding = 26.0;
    Widget content = isLoading
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SkeletonLoader(
                          height: 16,
                          width: screenWidth * 0.15,
                          borderRadius: 4,
                        ),
                        const SizedBox(height: 8),
                        SkeletonLoader(
                          height: 14,
                          width: screenWidth * 0.12,
                          borderRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SkeletonLoader(
                    height: 28,
                    width: 72,
                    borderRadius: 8,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SkeletonLoader(
                height: 14,
                width: screenWidth * 0.18,
                borderRadius: 4,
              ),
              const SizedBox(height: 8),
              SkeletonLoader(
                height: 14,
                width: screenWidth * 0.16,
                borderRadius: 4,
              ),
              const SizedBox(height: 8),
              SkeletonLoader(
                height: 14,
                width: screenWidth * 0.2,
                borderRadius: 4,
              ),
              const SizedBox(height: 8),
              SkeletonLoader(
                height: 14,
                width: screenWidth * 0.22,
                borderRadius: 4,
              ),
              const SizedBox(height: 8),
              SkeletonLoader(
                height: 14,
                width: screenWidth * 0.24,
                borderRadius: 4,
              ),
              const SizedBox(height: 8),
              SkeletonLoader(
                height: 14,
                width: screenWidth * 0.2,
                borderRadius: 4,
              ),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextComponent(
                          labelText: valet!.name,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                        ),
                        const SizedBox(height: 2),
                        TextComponent(
                          labelText: valet!.phone,
                          fontSize: phoneFontSize,
                          color: AppColors.mutedText,
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextComponent(
                      labelText:
                          '${t.get(TextConstants.carsPickedUpLabel)}${valet!.carsPickedUp}',
                      fontSize: bodyFontSize,
                      color: AppColors.black,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextComponent(
                      labelText:
                          '${t.get(TextConstants.carsHandedOverLabel)}${valet!.carsHandedOver}',
                      fontSize: bodyFontSize,
                      color: AppColors.black,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextComponent(
                      labelText:
                          '${t.get(TextConstants.onBreakDurationLabel)}${valet!.onBreakDurationMinutes}${t.get(TextConstants.minsLabel)}',
                      fontSize: bodyFontSize,
                      color: AppColors.black,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextComponent(
                      labelText:
                          '${t.get(TextConstants.clockInAtLabel)}${valet!.clockInAt.isNotEmpty ? TimeUtils.formatUtcToIstFullDateTime(valet!.clockInAt) : 'N/A'}',
                      fontSize: bodyFontSize,
                      color: AppColors.black,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
              if (valet!.clockOutAt.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: TextComponent(
                        labelText:
                            '${t.get(TextConstants.clockOutAtLabel)}${TimeUtils.formatUtcToIstFullDateTime(valet!.clockOutAt)}',
                        fontSize: bodyFontSize,
                        color: AppColors.black,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextComponent(
                      labelText:
                          '${t.get(TextConstants.lastActivityLabel)}${valet!.lastActivity.isNotEmpty ? TimeUtils.formatUtcToIstFullDateTime(valet!.lastActivity) : 'N/A'}',
                      fontSize: bodyFontSize,
                      color: AppColors.black,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
              // Logout button in box: only when valet is online (available / on duty / on break)
              if (ValetUtils.isOnline(valet!.status) &&
                  onLogoutValet != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => onLogoutValet!(valet!),
                    icon: const Icon(Icons.logout,
                        size: 20, color: AppColors.error),
                    label: TextComponent(
                      labelText: t.get(TextConstants.logout),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ],
          );

    final container = Container(
      padding: const EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey.withOpacity(0.3)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          // Status from API at top-right (Available, On Duty, On Break, Offline)
          if (valet != null && !isLoading)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: ValetUtils.getStatusColor(valet!.status)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: ValetUtils.getStatusColor(valet!.status)
                        .withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: TextComponent(
                  labelText: ValetUtils.translatedStatusLabel(valet!.status, t),
                  fontSize: smallFontSize.clamp(9.0, 12.0),
                  fontWeight: FontWeight.w600,
                  color: ValetUtils.getStatusColor(valet!.status),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap != null && valet != null && !isLoading) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: container,
        ),
      );
    }
    return container;
  }
}
