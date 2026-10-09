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
import 'package:niloufer_valet_mobile/ui/driver/qr_reader/qr_widgets/qr_processing_widget.dart';

class QrStatusDisplayWidget extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;
  final bool isTablet;
  final bool isDesktop;

  const QrStatusDisplayWidget({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.isTablet,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return BlocBuilder<QrBloc, QrState>(
      builder: (context, state) {
        final scanned = state.scannedCode;
        final isProcessing = state.isProcessing;
        final successMsg = state.successMessage;
        final errorMsg = state.errorMessage;
        final qrData = state.qrData;
        final shouldStopScanner = state.shouldStopScanner;

        if (isProcessing && scanned != null) {
          return QrProcessingWidget(
            scanned: scanned,
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            isTablet: isTablet,
            isDesktop: isDesktop,
          );
        }

        // Show success with card number and rescan button
        if (successMsg != null && qrData != null && shouldStopScanner) {
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
                        labelText: t.get(TextConstants.cardNumberLabel),
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
                        labelText: qrData.cardNumber.toString(),
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
                SizedBox(height: screenHeight * 0.015),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<QrBloc>().add(const QrClearForRescan());
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.01),
                      ),
                      padding:
                          EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                    ),
                    child: TextComponent(
                      labelText: t.get(TextConstants.rescanButton),
                      fontSize: isDesktop
                          ? screenWidth * 0.012
                          : isTablet
                              ? screenWidth * 0.018
                              : screenWidth * 0.03,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Show error with rescan button
        if (errorMsg != null && scanned != null && shouldStopScanner) {
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
                        labelText: errorMsg,
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
                SizedBox(height: screenHeight * 0.015),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<QrBloc>().add(const QrClearForRescan());
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.01),
                      ),
                      padding:
                          EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                    ),
                    child: TextComponent(
                      labelText: t.get(TextConstants.rescanButton),
                      fontSize: isDesktop
                          ? screenWidth * 0.012
                          : isTablet
                              ? screenWidth * 0.018
                              : screenWidth * 0.03,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
