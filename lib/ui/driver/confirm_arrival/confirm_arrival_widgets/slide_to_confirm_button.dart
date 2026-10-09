import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/countdown_cta_button.dart';

class SlideToConfirmButton extends StatelessWidget {
  final String sessionId;
  final bool isLoading;
  final VoidCallback onConfirm;
  final bool enabled;
  final int disabledRemainingSeconds;
  final bool useBigStyle;

  const SlideToConfirmButton({
    super.key,
    required this.sessionId,
    required this.isLoading,
    required this.onConfirm,
    this.enabled = true,
    this.disabledRemainingSeconds = 0,
    this.useBigStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final countdown =
        !enabled && disabledRemainingSeconds > 0 ? disabledRemainingSeconds : 0;

    if (useBigStyle) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return CountdownCtaButton(
            label: t.getByKey(
              'slideToConfirmArrival',
              TextConstants.slideToConfirmArrival,
            ),
            onPressed: onConfirm,
            isLoading: isLoading,
            countdownSeconds: countdown,
            iconWhenEnabled: Icons.my_location,
            height: constraints.maxHeight,
            useBigFont: true,
          );
        },
      );
    }

    return CountdownCtaButton(
      label: t.getByKey(
        'slideToConfirmArrival',
        TextConstants.slideToConfirmArrival,
      ),
      onPressed: onConfirm,
      isLoading: isLoading,
      countdownSeconds: countdown,
      iconWhenEnabled: Icons.my_location,
    );
  }
}
