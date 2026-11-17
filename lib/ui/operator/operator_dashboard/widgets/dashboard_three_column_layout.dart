import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:evalet/models/operator/operator_dashboard/operator_available_drivers_response.dart';
import 'package:evalet/models/operator/operator_dashboard/retrieval_requests_response.dart';
import 'package:evalet/services/translations/app_translations_notifier.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/text_constants.dart';
import 'package:evalet/ui/common/widgets/text.dart';
import 'package:evalet/ui/operator/operator_dashboard/widgets/available_drivers_horizontal_section.dart';
import 'package:evalet/ui/operator/operator_dashboard/widgets/retrieval_request_column.dart';

class DashboardThreeColumnLayout extends StatelessWidget {
  final RetrievalRequestsResponse retrievalRequests;
  final OperatorAvailableDriversResponse availableDrivers;
  final VoidCallback onAssignmentComplete;
  final bool autoAssignEnabled;
  final bool isLoading;
  final Set<String> highlightedRequestIds;

  const DashboardThreeColumnLayout({
    super.key,
    required this.retrievalRequests,
    required this.availableDrivers,
    required this.onAssignmentComplete,
    required this.autoAssignEnabled,
    this.isLoading = false,
    this.highlightedRequestIds = const <String>{},
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Available Drivers (top, horizontal scroll) ---
        AvailableDriversHorizontalSection(
          availableDrivers: availableDrivers,
          retrievalRequests: retrievalRequests,
          isLoading: isLoading,
          autoAssignEnabled: autoAssignEnabled,
        ),
        const SizedBox(height: 12),
        // --- Retrieval Requests (two columns) ---
        TextComponent(
          labelText: t.get(TextConstants.retrievalRequests),
          color: AppColors.black,
          fontSize: MediaQuery.of(context).size.height * 0.015,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: RetrievalRequestColumn(
                  retrievalRequests: retrievalRequests,
                  availableDrivers: availableDrivers,
                  onAssignmentComplete: onAssignmentComplete,
                  autoAssignEnabled: autoAssignEnabled,
                  isLoading: isLoading,
                  isLeftColumn: true,
                  highlightedRequestIds: highlightedRequestIds,
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.02),
              Expanded(
                flex: 1,
                child: RetrievalRequestColumn(
                  retrievalRequests: retrievalRequests,
                  availableDrivers: availableDrivers,
                  onAssignmentComplete: onAssignmentComplete,
                  autoAssignEnabled: autoAssignEnabled,
                  isLoading: isLoading,
                  isLeftColumn: false,
                  highlightedRequestIds: highlightedRequestIds,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
