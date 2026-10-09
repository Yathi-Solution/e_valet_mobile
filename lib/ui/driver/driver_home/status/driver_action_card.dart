import 'package:flutter/material.dart';
import 'package:niloufer_valet_mobile/ui/common/button_metrics.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';

/// Action card (Park Vehicle / Retrieve Vehicle) per design system.
class DriverActionCard extends StatelessWidget {
  final String imagePath;
  final String buttonLabel;
  final int notificationCount;
  final VoidCallback? onTap;
  final double screenWidth;
  final double screenHeight;
  final bool isTablet;
  final bool isDesktop;

  const DriverActionCard({
    super.key,
    required this.imagePath,
    required this.buttonLabel,
    this.notificationCount = 0,
    this.onTap,
    required this.screenWidth,
    required this.screenHeight,
    required this.isTablet,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final isTappable = onTap != null;
    // Match login card outline (coral accent, 2px).
    final cardRadius = BorderRadius.circular(
      (screenWidth * 0.05).clamp(12.0, 20.0),
    );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: cardRadius,
        border: Border.all(
          color: AppColors.accent,
          width: 2,
        ),
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: isTappable ? onTap : null,
          borderRadius: cardRadius,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 120),
                  child: Image.asset(
                    imagePath,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isTappable ? onTap : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnDark,
                      elevation: 0,
                      padding: ButtonMetrics.actionBarPadding(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ButtonMetrics.actionBarRadius(context),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextComponent(
                          labelText: buttonLabel,
                          fontSize: ButtonMetrics.actionBarFontSize(
                            context,
                            isTablet: isTablet,
                            isDesktop: isDesktop,
                          ),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOnDark,
                        ),
                        if (notificationCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Center(
                              child: TextComponent(
                                labelText: notificationCount > 99
                                    ? '99+'
                                    : notificationCount.toString(),
                                fontSize: isDesktop
                                    ? 10
                                    : isTablet
                                        ? 12
                                        : 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
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
