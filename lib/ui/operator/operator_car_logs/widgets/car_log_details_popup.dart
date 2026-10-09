import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/car_log.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/bloc/operator/car_logs/car_logs_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/operator/car_logs/car_logs_event.dart';
import 'simple_detail_row.dart';
import 'status_detail_row.dart';

class CarLogDetailsPopup extends StatefulWidget {
  final CarLog carLog;
  final Function onClose;

  const CarLogDetailsPopup({
    super.key,
    required this.carLog,
    required this.onClose,
  });

  @override
  State<CarLogDetailsPopup> createState() => _CarLogDetailsPopupState();
}

class _CarLogDetailsPopupState extends State<CarLogDetailsPopup> {
  late TextEditingController _statusController;
  String _selectedStatus = '';
  bool _isSubmitting = false;

  // Define available status options
  final List<String> _statusOptions = [
    'PARKED',
    'ARRIVED',
    'COMPLETED',
  ];

  @override
  void initState() {
    super.initState();
    _statusController =
        TextEditingController(text: widget.carLog.displayStatus);
    // Normalize the status to match our dropdown options
    _selectedStatus = _normalizeStatus(widget.carLog.displayStatus);
  }

  String _normalizeStatus(String status) {
    // Convert common status variations to our standardized format
    switch (status.toLowerCase()) {
      case 'checked_in':
      case 'checked in':
        return 'CHECKED_IN';
      case 'parked':
        return 'PARKED';
      case 'retrieval_requested':
      case 'retrieval requested':
        return 'RETRIEVAL_REQUESTED';
      case 'assigned':
        return 'ASSIGNED';
      case 'accepted':
        return 'ACCEPTED';
      case 'arrived':
        return 'ARRIVED';
      case 'reparking':
      case 're-parking':
        return 'REPARKING';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
      case 'canceled':
        return 'CANCELLED';
      default:
        // If status doesn't match any option, default to first option
        return _statusOptions.first;
    }
  }

  @override
  void dispose() {
    _statusController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_selectedStatus.isEmpty ||
        _selectedStatus == widget.carLog.displayStatus) {
      widget.onClose();
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Add update event to bloc
      final bloc = context.read<CarLogsBloc>();
      bloc.add(UpdateCarLogStatus(
        sessionId: widget.carLog.sessionId,
        newStatus: _selectedStatus,
      ));

      widget.onClose();
    } catch (e) {
      // Show error if needed
      SnackBars.showErrorSnackBar(
        context,
        TextConstants.failedToUpdateStatus(getDisplayErrorMessage(e)),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final screenSize = MediaQuery.of(context).size;

    return SizedBox.expand(
      child: Stack(
        children: [
          // Block taps outside so the popup only closes via Close / Cancel / Submit
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
            ),
          ),
          Center(
            child: Dialog(
              backgroundColor: AppColors.transparent,
              insetPadding: EdgeInsets.zero,
              child: Container(
                width: screenSize.width * 0.8,
                constraints: BoxConstraints(
                  maxWidth: 600,
                  maxHeight: screenSize.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          TextComponent(
                            labelText: t.get(TextConstants.carLogDetailsTitle),
                            color: AppColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => widget.onClose(),
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SimpleDetailRow(
                                label: t.get(TextConstants.tagNumberLabel),
                                value: widget.carLog.tagNumber.toString()),
                            const SizedBox(height: 16),
                            SimpleDetailRow(
                                label: t.get(TextConstants.parkedByLabel),
                                value: widget.carLog.parkedBy.phone.isNotEmpty
                                    ? '${widget.carLog.parkedBy.name} (${widget.carLog.parkedBy.phone})'
                                    : widget.carLog.parkedBy.name),
                            const SizedBox(height: 16),
                            StatusDetailRow(
                              label: t.getByKey('carStatusLabel',
                                  TextConstants.carStatusLabel),
                              selectedStatus: _selectedStatus,
                              statusOptions: _statusOptions,
                              onStatusChanged: (value) {
                                setState(() {
                                  _selectedStatus = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Footer with buttons
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                              color: AppColors.grey.withOpacity(0.3)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => widget.onClose(),
                            child: TextComponent(
                              labelText: t.get(TextConstants.cancelButton),
                              color: AppColors.mutedText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.white),
                                    ),
                                  )
                                : TextComponent(
                                    labelText: t.getByKey('submitButton',
                                        TextConstants.submitButton),
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
