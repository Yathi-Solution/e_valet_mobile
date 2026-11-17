import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:evalet/services/translations/app_translations_notifier.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/widgets/text.dart';

class SliderActionButton extends StatelessWidget {
  final String labelText;
  final VoidCallback onSlideComplete;
  final Color buttonColor;
  final Color backgroundColor;
  final Color? labelColor;
  final IconData icon;
  final double? width;
  final double? height;
  final double? radius;
  final bool isLoading;
  final String? loadingText;
  final bool isRound;

  const SliderActionButton({
    super.key,
    required this.labelText,
    required this.onSlideComplete,
    this.buttonColor = AppColors.success,
    this.backgroundColor = AppColors.white,
    this.labelColor,
    this.icon = Icons.check_rounded,
    this.width,
    this.height,
    this.radius,
    this.isLoading = false,
    this.loadingText,
    this.isRound = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonWidth = width ?? constraints.maxWidth;

        // If loading, show disabled state
        if (isLoading) {
          final buttonHeight = height ?? 60.0;
          final calculatedRadius = isRound ? buttonHeight / 2 : (radius ?? 12);

          return Container(
            width: buttonWidth,
            height: buttonHeight,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(calculatedRadius),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(buttonColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextComponent(
                    labelText: t.get(loadingText ?? labelText),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: labelColor ?? AppColors.black,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final buttonHeight = height ?? 60.0;

        // Calculate radius based on shape preference
        final calculatedRadius = isRound
            ? buttonHeight / 2 // Round: radius = half of height
            : (radius ?? 12); // Square/rounded: use provided radius or default

        final effectiveLabelColor = labelColor ?? AppColors.black;

        return SizedBox(
          width: buttonWidth,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: isLoading ? null : onSlideComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: effectiveLabelColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(calculatedRadius),
                side: BorderSide(color: buttonColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: buttonColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: TextComponent(
                    labelText: labelText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: effectiveLabelColor,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
