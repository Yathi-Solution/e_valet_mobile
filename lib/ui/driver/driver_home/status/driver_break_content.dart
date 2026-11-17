import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:evalet/services/translations/app_translations_notifier.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/widgets/text.dart';
import 'package:evalet/ui/common/widgets/elevated_button.dart';
import 'package:evalet/ui/common/text_constants.dart';

class DriverBreakContent extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;
  final bool isTablet;
  final bool isDesktop;
  final VoidCallback? onBreakEnd;

  const DriverBreakContent({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.isTablet,
    required this.isDesktop,
    this.onBreakEnd,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: screenHeight * 0.05),
        // Break title
        TextComponent(
          labelText: t.getByKey('takingBreak', TextConstants.takingBreak),
          fontSize: isDesktop
              ? screenWidth * 0.018
              : isTablet
                  ? screenWidth * 0.028
                  : screenWidth * 0.05,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: screenHeight * 0.04),
        // Coffee cup SVG
        SvgPicture.asset(
          'assets/svg/cup.svg',
          width: isDesktop
              ? screenWidth * 0.15
              : isTablet
                  ? screenWidth * 0.25
                  : screenWidth * 0.4,
          height: isDesktop
              ? screenWidth * 0.15
              : isTablet
                  ? screenWidth * 0.25
                  : screenWidth * 0.4,
        ),
        SizedBox(height: screenHeight * 0.04),
        // Relax and restart message
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.1,
          ),
          child: TextComponent(
            labelText:
                t.getByKey('relaxAndRestart', TextConstants.relaxAndRestart),
            fontSize: isDesktop
                ? screenWidth * 0.012
                : isTablet
                    ? screenWidth * 0.02
                    : screenWidth * 0.035,
            fontWeight: FontWeight.w400,
            color: AppColors.black,
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: screenHeight * 0.05),
        // End break button
        if (onBreakEnd != null)
          ElevatedButtonComponent(
            labelText: t.get(TextConstants.endBreak),
            onPressed: onBreakEnd!,
            elevatedButtonBackgroundColor: AppColors.primary,
            fontColor: AppColors.white,
            fontSize: isDesktop
                ? screenWidth * 0.014
                : isTablet
                    ? screenWidth * 0.024
                    : screenWidth * 0.04,
            fontWeight: FontWeight.w600,
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.08,
              vertical: screenHeight * 0.015,
            ),
            radius: 12.0,
          ),
        SizedBox(height: screenHeight * 0.02),
      ],
    );
  }
}
