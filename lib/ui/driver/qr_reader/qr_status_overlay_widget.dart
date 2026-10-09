import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/bloc/qr/qr_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/qr/qr_event.dart';
import 'package:niloufer_valet_mobile/bloc/qr/qr_state.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';

class QrStatusOverlayWidget extends StatelessWidget {
  final QrState state;
  final double screenWidth;
  final double screenHeight;
  final bool isTablet;
  final bool isDesktop;

  const QrStatusOverlayWidget({
    super.key,
    required this.state,
    required this.screenWidth,
    required this.screenHeight,
    required this.isTablet,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final isSuccess = state.qrData != null;

    // Brighter colors for better visibility
    final successColor = AppColors.qrSuccessColor;
    final errorColor = AppColors.qrErrorColor;
    final successBg = AppColors.qrSuccessBg;
    final errorBg = AppColors.qrErrorBg;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.06,
        vertical: screenHeight * 0.02,
      ),
      decoration: BoxDecoration(
        color: isSuccess ? successBg : errorBg,
        borderRadius: BorderRadius.circular(screenWidth * 0.025),
        border: Border.all(
          color: isSuccess ? successColor : errorColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isSuccess ? successColor : errorColor).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon and message row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.015),
                decoration: BoxDecoration(
                  color: isSuccess ? successColor : errorColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_rounded : Icons.close_rounded,
                  color: AppColors.white,
                  size: isDesktop
                      ? screenWidth * 0.025
                      : isTablet
                          ? screenWidth * 0.035
                          : screenWidth * 0.05,
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Flexible(
                child: TextComponent(
                  labelText: isSuccess
                      ? t.get(TextConstants.scannedSuccess)
                      : (state.errorMessage ?? t.get(TextConstants.errorLabel)),
                  fontSize: isDesktop
                      ? screenWidth * 0.012
                      : isTablet
                          ? screenWidth * 0.018
                          : screenWidth * 0.026,
                  fontWeight: FontWeight.w700,
                  color: isSuccess ? successColor : errorColor,
                  letterSpacing: 0.3,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // Card number display (only for success)
          if (isSuccess && state.qrData != null) ...[
            SizedBox(height: screenHeight * 0.015),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.015,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(screenWidth * 0.015),
                border: Border.all(
                  color: successColor.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: successColor.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextComponent(
                    labelText: t.get(TextConstants.cardLabel),
                    fontSize: isDesktop
                        ? screenWidth * 0.016
                        : isTablet
                            ? screenWidth * 0.024
                            : screenWidth * 0.035,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedText,
                  ),
                  TextComponent(
                    labelText: state.qrData!.cardNumber.toString(),
                    fontSize: isDesktop
                        ? screenWidth * 0.022
                        : isTablet
                            ? screenWidth * 0.032
                            : screenWidth * 0.048,
                    fontWeight: FontWeight.w800,
                    color: successColor,
                  ),
                ],
              ),
            ),
          ],
          // Rescan button
          SizedBox(height: screenHeight * 0.015),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<QrBloc>().add(const QrClearForRescan());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSuccess ? successColor : errorColor,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.012),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: TextComponent(
                labelText: t.get(TextConstants.rescanButton),
                fontSize: isDesktop
                    ? screenWidth * 0.011
                    : isTablet
                        ? screenWidth * 0.016
                        : screenWidth * 0.022,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
