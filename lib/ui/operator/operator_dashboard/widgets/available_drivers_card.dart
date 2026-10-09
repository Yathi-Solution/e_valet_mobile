import 'package:flutter/material.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/available_drivers.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_dashboard/widgets/compact_driver_content.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_dashboard/widgets/driver_card_content.dart';

class AvailableDriversCard extends StatelessWidget {
  final AvailableDriver driver;
  final bool isRecommended;
  final int? recommendedCardNumber;

  /// When true, shows only name and phone (max 1 line each) and card width fits content.
  final bool compact;

  /// When false (e.g. auto mode enabled), drag is disabled.
  final bool dragEnabled;

  const AvailableDriversCard({
    super.key,
    required this.driver,
    this.isRecommended = false,
    this.recommendedCardNumber,
    this.compact = false,
    this.dragEnabled = true,
  });

  Widget _buildCompactChild(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.02,
        vertical: MediaQuery.of(context).size.height * 0.008,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: isRecommended
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: isRecommended
                ? AppColors.primary.withOpacity(0.2)
                : AppColors.grey.withOpacity(0.1),
            spreadRadius: isRecommended ? 1.5 : 1,
            blurRadius: isRecommended ? 6 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CompactDriverContent(
            driver: driver,
            isRecommended: isRecommended,
            recommendedCardNumber: recommendedCardNumber,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      final child = _buildCompactChild(context);
      if (!dragEnabled) {
        return child;
      }
      return LongPressDraggable<AvailableDriver>(
        data: driver,
        delay: const Duration(milliseconds: 300),
        hapticFeedbackOnStart: true,
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Opacity(
            opacity: 0.8,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.02,
                vertical: MediaQuery.of(context).size.height * 0.008,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CompactDriverContent(
                driver: driver,
                isRecommended: isRecommended,
                recommendedCardNumber: recommendedCardNumber,
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.02,
              vertical: MediaQuery.of(context).size.height * 0.008,
            ),
            decoration: BoxDecoration(
              color: AppColors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CompactDriverContent(
              driver: driver,
              isRecommended: isRecommended,
              recommendedCardNumber: recommendedCardNumber,
            ),
          ),
        ),
        child: child,
      );
    }

    final nonCompactChild = Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height * 0.015,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.01,
        vertical: MediaQuery.of(context).size.height * 0.01,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: null,
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          DriverCardContent(driver: driver),
        ],
      ),
    );

    if (!dragEnabled) {
      return nonCompactChild;
    }

    return LongPressDraggable<AvailableDriver>(
      data: driver,
      delay: const Duration(milliseconds: 300),
      hapticFeedbackOnStart: true,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: 0.8,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.3,
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.01,
              vertical: MediaQuery.of(context).size.height * 0.01,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: DriverCardContent(driver: driver),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: Container(
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.015,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.01,
            vertical: MediaQuery.of(context).size.height * 0.01,
          ),
          decoration: BoxDecoration(
            color: AppColors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DriverCardContent(driver: driver),
        ),
      ),
      child: nonCompactChild,
    );
  }
}
