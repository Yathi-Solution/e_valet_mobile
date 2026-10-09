import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/available_drivers.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/utils/driver_utils.dart';

/// Compact content: name and phone only, each max 1 line. Card width fits content.
/// When [isRecommended] is true and [recommendedCardNumber] is set, shows "Recommended for card X".
class CompactDriverContent extends StatelessWidget {
  final AvailableDriver driver;
  final bool isRecommended;
  final int? recommendedCardNumber;

  const CompactDriverContent({
    super.key,
    required this.driver,
    this.isRecommended = false,
    this.recommendedCardNumber,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: TextComponent(
                labelText: DriverUtils.getInitials(driver.name),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.015,
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextComponent(
                  labelText: driver.name,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.002,
                ),
                TextComponent(
                  labelText: driver.phone,
                  fontSize: 12,
                  color: AppColors.mutedText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
        if (isRecommended && recommendedCardNumber != null) ...[
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.004,
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.015,
              vertical: MediaQuery.of(context).size.height * 0.003,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: TextComponent(
              labelText: t.get(TextConstants.recommendedForCard(
                recommendedCardNumber!,
              )),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }
}
