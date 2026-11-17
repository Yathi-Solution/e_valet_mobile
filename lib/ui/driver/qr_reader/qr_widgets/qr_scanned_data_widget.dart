import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:evalet/services/translations/app_translations_notifier.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/text_constants.dart';
import 'package:evalet/ui/common/widgets/text.dart';

class QrScannedDataWidget extends StatelessWidget {
  final String scanned;
  final double screenWidth;
  final double screenHeight;
  final bool isTablet;
  final bool isDesktop;

  const QrScannedDataWidget({
    super.key,
    required this.scanned,
    required this.screenWidth,
    required this.screenHeight,
    required this.isTablet,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      margin: EdgeInsets.only(bottom: screenHeight * 0.01),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        border: Border.all(
          color: AppColors.primary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextComponent(
            labelText: t.get(TextConstants.scannedDataLabel),
            fontSize: isDesktop
                ? screenWidth * 0.012
                : isTablet
                    ? screenWidth * 0.018
                    : screenWidth * 0.03,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
            textAlign: TextAlign.left,
          ),
          SizedBox(height: screenHeight * 0.01),
          TextComponent(
            labelText: scanned,
            fontSize: isDesktop
                ? screenWidth * 0.014
                : isTablet
                    ? screenWidth * 0.02
                    : screenWidth * 0.035,
            fontWeight: FontWeight.w500,
            color: AppColors.black,
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }
}
