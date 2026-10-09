import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/operator_available_drivers_response.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/retrieval_requests_response.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/skeleton_loader.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_dashboard/widgets/retrieval_request_card.dart';

/// One column of retrieval request cards.
/// Left column: only RETRIEVAL_REQUESTED. Right column: all other statuses (Assigned, Accepted, Arrived, etc.).
/// Handles loading skeleton, empty state, and drag-target scroll.
class RetrievalRequestColumn extends StatefulWidget {
  final RetrievalRequestsResponse retrievalRequests;
  final OperatorAvailableDriversResponse availableDrivers;
  final VoidCallback onAssignmentComplete;
  final bool autoAssignEnabled;
  final bool isLoading;
  final bool isLeftColumn;
  final Set<String> highlightedRequestIds;

  const RetrievalRequestColumn({
    super.key,
    required this.retrievalRequests,
    required this.availableDrivers,
    required this.onAssignmentComplete,
    required this.autoAssignEnabled,
    this.isLoading = false,
    this.isLeftColumn = true,
    this.highlightedRequestIds = const <String>{},
  });

  @override
  State<RetrievalRequestColumn> createState() => _RetrievalRequestColumnState();
}

class _RetrievalRequestColumnState extends State<RetrievalRequestColumn> {
  final ScrollController _scrollController = ScrollController();
  // Keep drag/drop implementation in codebase, but disabled on dashboard.
  static const bool _manualDragDropEnabled = false;

  static int _statusOrder(String status) {
    switch (status.toUpperCase()) {
      case 'RETRIEVAL_REQUESTED':
        return 0;
      case 'ASSIGNED':
        return 1;
      case 'ACCEPTED':
        return 2;
      case 'ARRIVED':
        return 3;
      default:
        return 4;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    if (widget.isLoading) {
      return _buildSkeleton(context);
    }

    final allRequests = widget.retrievalRequests.requests;

    if (allRequests.isEmpty) {
      return _buildEmpty(context);
    }

    // Left column: only RETRIEVAL_REQUESTED. Right column: all other statuses.
    final retrievalRequested = allRequests
        .where((r) => r.status.toUpperCase() == 'RETRIEVAL_REQUESTED')
        .toList();
    final otherStatuses = allRequests
        .where((r) => r.status.toUpperCase() != 'RETRIEVAL_REQUESTED')
        .toList()
      ..sort(
          (a, b) => _statusOrder(a.status).compareTo(_statusOrder(b.status)));

    final columnRequests =
        widget.isLeftColumn ? retrievalRequested : otherStatuses;

    if (columnRequests.isEmpty) {
      return Center(
        child: TextComponent(
          labelText: t.get(TextConstants.noPendingRetrievalRequests),
          fontSize: 14,
          color: AppColors.mutedText,
        ),
      );
    }

    final list = ListView.builder(
      controller: _scrollController,
      itemCount: columnRequests.length,
      itemBuilder: (context, index) {
        final request = columnRequests[index];
        return RetrievalRequestCard(
          request: request,
          availableDrivers: widget.availableDrivers.drivers,
          onAssignmentComplete: widget.onAssignmentComplete,
          autoAssignEnabled: widget.autoAssignEnabled,
          isHighlighted:
              widget.highlightedRequestIds.contains(request.sessionId),
        );
      },
    );

    if (!_manualDragDropEnabled) {
      return list;
    }

    return DragTarget<Object>(
      onMove: (details) {
        _handleAutoScroll(context, details.offset);
      },
      builder: (context, candidateData, rejectedData) {
        return list;
      },
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.015,
          ),
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.01),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLoader(
                height: MediaQuery.of(context).size.height * 0.02,
                width: MediaQuery.of(context).size.width * 0.15,
                borderRadius: 4,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              SkeletonLoader(
                height: MediaQuery.of(context).size.height * 0.015,
                width: MediaQuery.of(context).size.width * 0.1,
                borderRadius: 4,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 48, color: AppColors.grey),
          const SizedBox(height: 8),
          TextComponent(
            labelText: t.get(TextConstants.noPendingRetrievalRequests),
            fontSize: 14,
            color: AppColors.mutedText,
          ),
        ],
      ),
    );
  }

  void _handleAutoScroll(BuildContext context, Offset dragPosition) {
    if (!_scrollController.hasClients) return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final scrollAreaHeight = renderBox.size.height;
    const scrollThreshold = 100.0;
    const scrollSpeed = 10.0;

    if (dragPosition.dy < scrollThreshold) {
      final newOffset = _scrollController.offset - scrollSpeed;
      if (newOffset >= 0) {
        _scrollController.jumpTo(newOffset);
      }
    } else if (dragPosition.dy > scrollAreaHeight - scrollThreshold) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final newOffset = _scrollController.offset + scrollSpeed;
      if (newOffset <= maxScroll) {
        _scrollController.jumpTo(newOffset);
      }
    }
  }
}
