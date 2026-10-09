import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';

class QrProcessingWidget extends StatelessWidget {
  final String scanned;
  final double screenWidth;
  final double screenHeight;
  final bool isTablet;
  final bool isDesktop;

  const QrProcessingWidget({
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: isDesktop
                    ? screenWidth * 0.02
                    : isTablet
                        ? screenWidth * 0.03
                        : screenWidth * 0.05,
                height: isDesktop
                    ? screenWidth * 0.02
                    : isTablet
                        ? screenWidth * 0.03
                        : screenWidth * 0.05,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              TextComponent(
                labelText: t.get(TextConstants.processingQrCode),
                fontSize: isDesktop
                    ? screenWidth * 0.012
                    : isTablet
                        ? screenWidth * 0.018
                        : screenWidth * 0.03,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          Container(
            padding: EdgeInsets.all(screenWidth * 0.02),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(screenWidth * 0.01),
            ),
            child: TextComponent(
              labelText: scanned,
              fontSize: isDesktop
                  ? screenWidth * 0.011
                  : isTablet
                      ? screenWidth * 0.016
                      : screenWidth * 0.028,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
