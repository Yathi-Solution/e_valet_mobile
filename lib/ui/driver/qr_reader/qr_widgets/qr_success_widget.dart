import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';

class QrSuccessWidget extends StatelessWidget {
  final String successMsg;
  final String scanned;
  final double screenWidth;
  final double screenHeight;
  final bool isTablet;
  final bool isDesktop;

  const QrSuccessWidget({
    super.key,
    required this.successMsg,
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
        color: AppColors.qrSuccessBackground,
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        border: Border.all(
          color: AppColors.qrSuccessBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: AppColors.qrSuccessText,
                size: isDesktop
                    ? screenWidth * 0.025
                    : isTablet
                        ? screenWidth * 0.04
                        : screenWidth * 0.06,
              ),
              SizedBox(width: screenWidth * 0.02),
              Flexible(
                child: TextComponent(
                  labelText: successMsg,
                  fontSize: isDesktop
                      ? screenWidth * 0.012
                      : isTablet
                          ? screenWidth * 0.018
                          : screenWidth * 0.03,
                  fontWeight: FontWeight.w600,
                  color: AppColors.qrSuccessText,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(screenWidth * 0.03),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(screenWidth * 0.01),
              border: Border.all(
                color: AppColors.qrSuccessBorderLight,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextComponent(
                  labelText: t.get(TextConstants.scannedDataLabel),
                  fontSize: isDesktop
                      ? screenWidth * 0.01
                      : isTablet
                          ? screenWidth * 0.015
                          : screenWidth * 0.025,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  textAlign: TextAlign.left,
                ),
                SizedBox(height: screenHeight * 0.005),
                TextComponent(
                  labelText: scanned,
                  fontSize: isDesktop
                      ? screenWidth * 0.012
                      : isTablet
                          ? screenWidth * 0.018
                          : screenWidth * 0.032,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
