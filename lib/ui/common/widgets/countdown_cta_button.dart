import 'package:flutter/material.dart';
import 'package:niloufer_valet_mobile/ui/common/button_metrics.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
/// Full-width primary CTA with optional countdown badge on the left.
class CountdownCtaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final int countdownSeconds;
  final IconData? iconWhenEnabled;
  final double? height;
  final bool useBigFont;

  const CountdownCtaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.countdownSeconds = 0,
    this.iconWhenEnabled,
    this.height,
    this.useBigFont = false,
  });

  static Widget countdownBadge(int seconds) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: ButtonMetrics.countdownBadgeSize,
        minHeight: ButtonMetrics.countdownBadgeSize,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.nearBlack.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$seconds',
        style: const TextStyle(
          fontSize: ButtonMetrics.countdownBadgeFontSize,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
          height: 1.1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final disabled = countdownSeconds > 0;
    final effectiveOnPressed =
        (isLoading || disabled) ? null : onPressed;
    final effectiveHeight =
        height ?? ButtonMetrics.confirmHeight(context);
    final fontSize = useBigFont
        ? ButtonMetrics.confirmBigFontSize(context)
        : ButtonMetrics.confirmFontSize(context);

    final bool showLeading =
        isLoading || disabled || iconWhenEnabled != null;

    Widget? leading;
    if (isLoading) {
      leading = const SizedBox(
        width: ButtonMetrics.countdownBadgeSize,
        height: ButtonMetrics.countdownBadgeSize,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
        ),
      );
    } else if (disabled) {
      leading = countdownBadge(countdownSeconds);
    } else if (iconWhenEnabled != null) {
      leading = Icon(iconWhenEnabled, color: AppColors.white, size: 26);
    }

    final button = ElevatedButton(
      onPressed: effectiveOnPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.7),
        disabledForegroundColor: AppColors.white.withValues(alpha: 0.85),
        elevation: 0,
        minimumSize: Size(double.infinity, effectiveHeight),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(ButtonMetrics.confirmRadius),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: TextComponent(
              labelText: label,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showLeading && leading != null)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Center(child: leading),
            ),
        ],
      ),
    );

    return Semantics(
      button: true,
      enabled: effectiveOnPressed != null,
      label: disabled ? '$label, disabled for $countdownSeconds seconds' : label,
      child: button,
    );
  }
}
