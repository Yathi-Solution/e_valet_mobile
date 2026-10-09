import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';

class QrErrorWidget extends StatelessWidget {
  final String errorMsg;
  final String scanned;
  final double screenWidth;
  final double screenHeight;
  final bool isTablet;
  final bool isDesktop;

  const QrErrorWidget({
    super.key,
    required this.errorMsg,
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
        color: AppColors.qrErrorBackground,
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        border: Border.all(
          color: AppColors.error,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: isDesktop
                    ? screenWidth * 0.025
                    : isTablet
                        ? screenWidth * 0.04
                        : screenWidth * 0.06,
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: TextComponent(
                  labelText: t.get(TextConstants.errorProcessingQrCode),
                  fontSize: isDesktop
                      ? screenWidth * 0.012
                      : isTablet
                          ? screenWidth * 0.018
                          : screenWidth * 0.03,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                  textAlign: TextAlign.center,
                ),
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
            child: Column(
              children: [
                TextComponent(
                  labelText: '${t.get(TextConstants.scannedLabel)} $scanned',
                  fontSize: isDesktop
                      ? screenWidth * 0.01
                      : isTablet
                          ? screenWidth * 0.015
                          : screenWidth * 0.025,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.005),
                TextComponent(
                  labelText: errorMsg,
                  fontSize: isDesktop
                      ? screenWidth * 0.01
                      : isTablet
                          ? screenWidth * 0.015
                          : screenWidth * 0.025,
                  fontWeight: FontWeight.w400,
                  color: AppColors.error,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
