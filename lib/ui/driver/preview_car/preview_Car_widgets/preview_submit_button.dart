import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/button_metrics.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';

class PreviewSubmitButton extends StatelessWidget {
  final VoidCallback onSubmit;
  final bool isReparking;
  final bool isLoading;
  final bool isEnabled;
  final String? overrideLabel;

  const PreviewSubmitButton({
    super.key,
    required this.onSubmit,
    this.isReparking = false,
    this.isLoading = false,
    this.isEnabled = true,
    this.overrideLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final canPress = isEnabled && !isLoading;
    final buttonHeight = ButtonMetrics.submitHeight(context);
    final textSize = ButtonMetrics.submitFontSize(context);
    final radius = ButtonMetrics.submitRadius(context);

    final bgColor = AppColors.primary;

    return Semantics(
      button: true,
      enabled: canPress,
      label: overrideLabel ??
          (isReparking
              ? t.get(TextConstants.submitRePark)
              : t.getByKey('submitButton', TextConstants.submitButton)),
      child: SizedBox(
        width: double.infinity,
        height: buttonHeight,
        child: ElevatedButton(
          onPressed: canPress ? onSubmit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.disabledBackground,
            disabledForegroundColor: AppColors.disabledText,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: TextComponent(
                        labelText: overrideLabel ??
                            (isReparking
                                ? t.get(TextConstants.submitRePark)
                                : t.getByKey('submitButton',
                                    TextConstants.submitButton)),
                        fontSize: textSize,
                        fontWeight: FontWeight.w600,
                        color: canPress
                            ? AppColors.white
                            : AppColors.disabledText,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (overrideLabel == null && !isReparking)
                      Positioned(
                        right: 0,
                        child: Icon(
                          Icons.arrow_forward,
                          color: canPress
                              ? AppColors.white
                              : AppColors.disabledText,
                          size: textSize,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
