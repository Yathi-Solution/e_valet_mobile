import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/models/driver/session/assigned_session.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/driver/retrival_request/retrival_widgets/session_card.dart';

class RetrievalRequestSheet extends StatelessWidget {
  final AssignedSession? session;
  final String? message;
  final bool isLoading;
  final bool isAcceptLoading;
  final VoidCallback? onAccept;

  // Pass-to-driver section
  final bool isPassing;
  final VoidCallback? onPass;
  final String? passErrorMessage;

  const RetrievalRequestSheet({
    super.key,
    this.session,
    this.message,
    this.isLoading = false,
    this.isAcceptLoading = false,
    this.onAccept,
    this.isPassing = false,
    this.onPass,
    this.passErrorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    const horizontalPadding = 16.0;
    const verticalPadding = 12.0;
    final maxSheetHeight = screenHeight * 0.88;
    final isActionLocked = isAcceptLoading || isPassing;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding,
            top: verticalPadding,
            bottom: verticalPadding + bottomPadding,
          ),
          child: Container(
            constraints: BoxConstraints(maxHeight: maxSheetHeight),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow10,
                  blurRadius: 12,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Scrollable content — shrinks to fit; scrolls when content
                // exceeds the maxHeight cap on the parent Container.
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Drag handle (centred)
                        Center(
                          child: Container(
                            width: screenWidth * 0.16,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.greyLight,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        TextComponent(
                          labelText: t.get(TextConstants.retrievalRequest),
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                        const SizedBox(height: 12),
                        if (isLoading) ...[
                          const Center(child: CircularProgressIndicator()),
                          const SizedBox(height: 16),
                        ] else if (message != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: TextComponent(
                              labelText: message!,
                              textAlign: TextAlign.center,
                              fontSize: screenWidth * 0.04,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ] else if (session != null) ...[
                          SessionCard(session: session!, onAccept: onAccept),
                        ] else ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: TextComponent(
                              labelText: t
                                  .get(TextConstants.noActiveRetrievalRequests),
                              textAlign: TextAlign.center,
                              fontSize: screenWidth * 0.04,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],

                        // // Pass-to-driver section — only shown when a session is active
                        // if (session != null) ...[
                        //   const SizedBox(height: 4),
                        //   PassToDriverSection(
                        //     screenWidth: screenWidth,
                        //     isPassing: isPassing,
                        //     isDisabled: isActionLocked,
                        //     onPass: onPass,
                        //   ),
                        //   if (passErrorMessage != null &&
                        //       passErrorMessage!.trim().isNotEmpty)
                        //     Padding(
                        //       padding:
                        //           const EdgeInsets.only(top: 10, bottom: 4),
                        //       child: TextComponent(
                        //         labelText: passErrorMessage!,
                        //         fontSize: screenWidth * 0.035,
                        //         fontWeight: FontWeight.w600,
                        //         color: AppColors.error,
                        //       ),
                        //     ),
                        // ],
                      ],
                    ),
                  ),
                ),

                // Accept / Collect Keys button (current / first in queue)
                if (session != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    child: SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: isActionLocked
                            ? null
                            : (onAccept ?? () => Navigator.of(context).pop()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnDark,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isAcceptLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.textOnDark),
                                ),
                              )
                            : FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextComponent(
                                      labelText: t.getByKey('acceptRequest',
                                          TextConstants.acceptRequest),
                                      fontSize: screenWidth * 0.05,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textOnDark,
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: screenWidth * 0.06,
                                      color: AppColors.textOnDark,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
