import 'package:flutter/material.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';

class AppLogo extends StatelessWidget {
  /// Light-surface mark (white background, orange V, black L).
  static const assetPath = 'assets/images/vl_white.png';

  /// Dark-surface mark (black background, orange V, white L).
  static const assetPathOnDark = 'assets/images/vl_black.png';

  /// Square VL mark.
  static const aspectRatio = 1.0;

  final double height;
  final double? width;

  /// When true, uses [assetPathOnDark] (e.g. on the dark app bar).
  final bool onDarkBackground;

  /// Coral accent bar under the logo (e.g. drawer branding).
  final bool showAccentUnderline;

  const AppLogo({
    super.key,
    required this.height,
    this.width,
    this.onDarkBackground = false,
    this.showAccentUnderline = false,
  });

  @override
  Widget build(BuildContext context) {
    final logoWidth = width ?? height * aspectRatio;
    final path = onDarkBackground ? assetPathOnDark : assetPath;

    final logo = SizedBox(
      width: logoWidth,
      height: height,
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        alignment: Alignment.center,
      ),
    );

    if (!showAccentUnderline) return logo;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        logo,
        const SizedBox(height: 6),
        Container(
          height: 3,
          width: logoWidth,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
