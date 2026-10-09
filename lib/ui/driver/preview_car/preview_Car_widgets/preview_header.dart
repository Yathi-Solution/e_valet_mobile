import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/card_number_badge.dart';

class PreviewHeader extends StatelessWidget {
  final bool isReparking;
  final String? cardNumber;

  const PreviewHeader({
    super.key,
    this.isReparking = false,
    this.cardNumber,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final screenWidth = MediaQuery.of(context).size.width;

    final title = isReparking
        ? t.get(TextConstants.reParkingEntryReview)
        : t.get(TextConstants.reviewEntry);

    final card = (cardNumber ?? '').trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextComponent(
            labelText: title,
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        if (card.isNotEmpty) ...[
          const SizedBox(width: 12),
          CardNumberBadge(
            label: t.get(TextConstants.cardNumberLabel),
            value: card,
            compact: true,
          ),
        ],
      ],
    );
  }
}
