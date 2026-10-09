import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/available_drivers.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/operator_available_drivers_response.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/retrieval_request.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/retrieval_requests_response.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/skeleton_loader.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_dashboard/widgets/available_drivers_card.dart';

/// Horizontal scrollable section showing available (free) drivers at the top of the dashboard.
class AvailableDriversHorizontalSection extends StatelessWidget {
  final OperatorAvailableDriversResponse availableDrivers;
  final RetrievalRequestsResponse retrievalRequests;
  final bool isLoading;

  /// When true (auto mode), drag is disabled.
  final bool autoAssignEnabled;

  const AvailableDriversHorizontalSection({
    super.key,
    required this.availableDrivers,
    required this.retrievalRequests,
    this.isLoading = false,
    this.autoAssignEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextComponent(
          labelText: t.get(TextConstants.availableValets),
          color: AppColors.black,
          fontSize: MediaQuery.of(context).size.height * 0.015,
        ),
        const SizedBox(height: 12),
        isLoading
            ? SizedBox(
                height: MediaQuery.of(context).size.height * 0.05,
                child: _buildSkeleton(context),
              )
            : _buildContent(context, t),
      ],
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          width: MediaQuery.of(context).size.width * 0.22,
          margin: EdgeInsets.only(
            right: MediaQuery.of(context).size.width * 0.015,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.01,
            vertical: MediaQuery.of(context).size.height * 0.01,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              SkeletonLoader(
                height: MediaQuery.of(context).size.width * 0.05,
                width: MediaQuery.of(context).size.width * 0.05,
                borderRadius: 100,
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.015),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                      height: MediaQuery.of(context).size.height * 0.015,
                      width: MediaQuery.of(context).size.width * 0.08,
                      borderRadius: 4,
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.005,
                    ),
                    SkeletonLoader(
                      height: MediaQuery.of(context).size.height * 0.008,
                      width: MediaQuery.of(context).size.width * 0.06,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static const String _retrievalRequested = 'RETRIEVAL_REQUESTED';

  /// Match by userId when available, otherwise by name (backward compatibility).
  bool _isRecommendedDriver(
    AvailableDriver driver,
    String? recommendedDriverId,
    String? recommendedDriverName,
  ) {
    if (recommendedDriverId != null && recommendedDriverId.isNotEmpty) {
      return driver.userId == recommendedDriverId;
    }
    return recommendedDriverName != null &&
        driver.name == recommendedDriverName;
  }

  Widget _buildContent(BuildContext context, AppTranslationsNotifier t) {
    var freeDrivers = availableDrivers.drivers
        .where((driver) => driver.status.toLowerCase() == 'free')
        .toList();

    // Only show "recommended" when there is a request still in RETRIEVAL_REQUESTED
    // whose parkedBy driver is actually in the free list. Use the first such request
    // so that after assigning card 107, the next card (e.g. 108) gets its driver
    // shown as recommended.
    final retrievalRequestedList = retrievalRequests.requests
        .where((r) => r.status.toUpperCase() == _retrievalRequested)
        .toList();

    RetrievalRequest? chosenRequest;
    for (final r in retrievalRequestedList) {
      final parkerInFreeList = freeDrivers.any((d) =>
          (r.parkedBy.userId != null &&
              r.parkedBy.userId!.isNotEmpty &&
              d.userId == r.parkedBy.userId) ||
          d.name == r.parkedBy.name);
      if (parkerInFreeList) {
        chosenRequest = r;
        break;
      }
    }

    String? recommendedDriverId;
    String? recommendedDriverName;
    int? recommendedCardNumber;
    if (chosenRequest != null) {
      recommendedDriverId = chosenRequest.parkedBy.userId;
      recommendedDriverName = chosenRequest.parkedBy.name;
      recommendedCardNumber = chosenRequest.cardNumber;
      // Show recommended driver at the start of the list.
      freeDrivers.sort((a, b) {
        final aMatch =
            _isRecommendedDriver(a, recommendedDriverId, recommendedDriverName);
        final bMatch =
            _isRecommendedDriver(b, recommendedDriverId, recommendedDriverName);
        if (aMatch) return -1;
        if (bMatch) return 1;
        return 0;
      });
    }

    if (freeDrivers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 40,
              color: AppColors.mutedText,
            ),
            const SizedBox(height: 8),
            TextComponent(
              labelText: t.getByKey('noAvailableDriversAtTheMoment',
                  TextConstants.noAvailableDrivers),
              fontSize: 14,
              color: AppColors.mutedText,
            ),
          ],
        ),
      );
    }

    return IntrinsicHeight(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < freeDrivers.length; i++) ...[
              if (i > 0)
                SizedBox(width: MediaQuery.of(context).size.width * 0.015),
              IntrinsicWidth(
                child: AvailableDriversCard(
                  key: ValueKey(
                    (freeDrivers[i].userId.isNotEmpty)
                        ? freeDrivers[i].userId
                        : 'driver_$i',
                  ),
                  driver: freeDrivers[i],
                  isRecommended: _isRecommendedDriver(
                    freeDrivers[i],
                    recommendedDriverId,
                    recommendedDriverName,
                  ),
                  recommendedCardNumber: recommendedCardNumber,
                  compact: true,
                  // Manual drag-and-drop assignment is disabled on dashboard.
                  dragEnabled: false,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
