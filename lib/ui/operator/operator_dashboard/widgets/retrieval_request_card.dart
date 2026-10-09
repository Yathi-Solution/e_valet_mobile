import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/bloc/operator/operator_dashboard/operator_dashboard_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/operator/operator_dashboard/operator_dashboard_event.dart';
import 'package:niloufer_valet_mobile/bloc/operator/operator_dashboard/operator_dashboard_state.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/available_drivers.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/retrieval_request.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/full_image_viewer_dialog.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/utils/retrieval_request_utils.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_dashboard/widgets/assignment_confirmation_dialog.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

class RetrievalRequestCard extends StatefulWidget {
  final RetrievalRequest request;
  final List<AvailableDriver> availableDrivers;
  final VoidCallback onAssignmentComplete;
  final bool autoAssignEnabled;
  final bool isHighlighted;

  const RetrievalRequestCard({
    super.key,
    required this.request,
    required this.availableDrivers,
    required this.onAssignmentComplete,
    required this.autoAssignEnabled,
    this.isHighlighted = false,
  });

  @override
  State<RetrievalRequestCard> createState() => _RetrievalRequestCardState();
}

class _RetrievalRequestCardState extends State<RetrievalRequestCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _highlightController;
  late final Animation<double> _highlightAnimation;
  // Keep drag/drop implementation in codebase, but disabled on dashboard.
  static const bool _manualDragDropEnabled = false;
  bool _isDraggingOver = false;

  void _callPhoneNumber(String phoneNumber) async {
    try {
      final called = await FlutterPhoneDirectCaller.callNumber(phoneNumber);
      if (called == null || !called) {
        SnackBars.showErrorSnackBar(context, 'Could not launch phone dialer');
      }
    } catch (e) {
      SnackBars.showErrorSnackBar(context, 'Could not launch phone dialer');
    }
  }

  bool get _isAssigned => widget.request.status.toUpperCase() == 'ASSIGNED';
  bool get _isAssignable =>
      RetrievalRequestUtils.isAssignable(widget.request.status);

  Color _statusColor() => RetrievalRequestUtils.getStatusColor(
        status: widget.request.status,
        waitingTime: widget.request.waitingTime,
      );

  String _statusLabel() => RetrievalRequestUtils.getStatusLabel(
        status: widget.request.status,
        waitingTime: widget.request.waitingTime,
      );

  void _showCancelAssignmentDialog() {
    final t = context.read<AppTranslationsNotifier>();
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(TextConstants.cancelAssignmentTitle),
        content: Text(TextConstants.cancelAssignmentMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(TextConstants.cancelText),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<OperatorDashboardBloc>().add(
                    CancelRetrievalAssignment(
                      sessionId: widget.request.sessionId,
                    ),
                  );
            },
            child: Text(
              t.get(TextConstants.cancelAssignmentConfirm),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignmentDialog(AvailableDriver driver) {
    final dashboardBloc = context.read<OperatorDashboardBloc>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          BlocListener<OperatorDashboardBloc, OperatorDashboardState>(
        bloc: dashboardBloc,
        listener: (context, state) {
          if (state is AssignmentSuccess) {
            Navigator.pop(dialogContext);
            SnackBars.showSuccessSnackBar(
              context,
              'Successfully assigned ${driver.name} to Card #${widget.request.cardNumber}',
            );
            widget.onAssignmentComplete();
          } else if (state is AssignmentError) {
            SnackBars.showErrorSnackBar(
              context,
              'Failed to assign driver: ${state.message}',
            );
          }
        },
        child: AssignmentConfirmationDialog(
          driver: driver,
          request: widget.request,
          onConfirm: () {
            dashboardBloc.add(
              AssignDriverToRetrieval(
                driverUserId: driver.userId,
                sessionId: widget.request.sessionId,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _highlightAnimation = CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeInOut,
    );

    if (widget.isHighlighted) {
      _highlightController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant RetrievalRequestCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isHighlighted != widget.isHighlighted) {
      if (widget.isHighlighted) {
        _highlightController.repeat(reverse: true);
      } else {
        _highlightController
          ..stop()
          ..value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final cardBody =
        BlocListener<OperatorDashboardBloc, OperatorDashboardState>(
      listenWhen: (prev, curr) =>
          curr is CancelAssignmentSuccess || curr is CancelAssignmentError,
      listener: (context, state) {
        if (state is CancelAssignmentSuccess &&
            state.response.sessionId == widget.request.sessionId) {
          SnackBars.showSuccessSnackBar(
            context,
            t.get(TextConstants.cancelAssignmentSuccess),
          );
          widget.onAssignmentComplete();
        } else if (state is CancelAssignmentError &&
            state.sessionId == widget.request.sessionId) {
          SnackBars.showErrorSnackBar(context, state.message);
        }
      },
      child: AnimatedBuilder(
        animation: _highlightAnimation,
        builder: (context, child) {
          final pulse = widget.isHighlighted ? _highlightAnimation.value : 0.0;
          final baseBorderColor = (_manualDragDropEnabled && _isDraggingOver)
              ? AppColors.accent
              : _statusColor();
          final baseBackgroundColor =
              (_manualDragDropEnabled && _isDraggingOver)
                  ? AppColors.accentSoft
                  : AppColors.cardBackground;
          final highlightBorderColor =
              Color.lerp(baseBorderColor, AppColors.accent, pulse) ??
                  baseBorderColor;
          final highlightBackgroundColor = Color.lerp(
                baseBackgroundColor,
                AppColors.accent.withOpacity(0.12),
                pulse,
              ) ??
              baseBackgroundColor;
          final baseShadowColor = (_manualDragDropEnabled && _isDraggingOver)
              ? AppColors.accent.withOpacity(0.3)
              : AppColors.grey.withOpacity(0.1);
          final highlightShadowColor = Color.lerp(
                baseShadowColor,
                AppColors.accent.withOpacity(0.35),
                pulse,
              ) ??
              baseShadowColor;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.015,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.01,
              vertical: MediaQuery.of(context).size.height * 0.01,
            ),
            decoration: BoxDecoration(
              color: highlightBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (_manualDragDropEnabled && _isDraggingOver)
                    ? AppColors.primary
                    : highlightBorderColor,
                width: (_manualDragDropEnabled && _isDraggingOver) ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_manualDragDropEnabled && _isDraggingOver)
                      ? baseShadowColor
                      : highlightShadowColor,
                  spreadRadius:
                      (_manualDragDropEnabled && _isDraggingOver) ? 2 : 1,
                  blurRadius:
                      (_manualDragDropEnabled && _isDraggingOver) ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle Image - tap to view full size
                GestureDetector(
                  onTap: widget.request.vehicle.photo.isNotEmpty
                      ? () => FullImageViewerDialog.show(
                            context,
                            widget.request.vehicle.photo,
                          )
                      : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.request.vehicle.photo.isNotEmpty
                        ? Image.network(
                            widget.request.vehicle.photo,
                            width: MediaQuery.of(context).size.width * 0.1,
                            height: MediaQuery.of(context).size.width * 0.1,
                            fit: BoxFit.fill,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: MediaQuery.of(context).size.width * 0.1,
                                height: MediaQuery.of(context).size.width * 0.1,
                                color: AppColors.grey.withOpacity(0.3),
                                child: Icon(
                                  Icons.directions_car,
                                  size:
                                      MediaQuery.of(context).size.width * 0.04,
                                  color: AppColors.mutedText,
                                ),
                              );
                            },
                          )
                        : Container(
                            width: MediaQuery.of(context).size.width * 0.1,
                            height: MediaQuery.of(context).size.width * 0.1,
                            color: AppColors.grey.withOpacity(0.3),
                            child: Icon(
                              Icons.directions_car,
                              size: MediaQuery.of(context).size.width * 0.04,
                              color: AppColors.mutedText,
                            ),
                          ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.012,
                ),
                // Information Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Card number, Status, and Parking Location
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: TextComponent(
                              labelText:
                                  '#${t.get(TextConstants.cardNumber)} ${widget.request.cardNumber}',
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.022,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width * 0.015,
                                  vertical: MediaQuery.of(context).size.height *
                                      0.005,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextComponent(
                                  labelText: t.get(_statusLabel()),
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.014,
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_isAssigned && !widget.autoAssignEnabled) ...[
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.01),
                                GestureDetector(
                                  onTap: _showCancelAssignmentDialog,
                                  child: Container(
                                    width: MediaQuery.of(context).size.width *
                                        0.05,
                                    height: MediaQuery.of(context).size.width *
                                        0.05,
                                    decoration: BoxDecoration(
                                      color: AppColors.cancelAssignmentIcon,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.cancelAssignmentIcon
                                              .withOpacity(0.5),
                                          offset: const Offset(2, 2),
                                          blurRadius: 2,
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.close,
                                      size: MediaQuery.of(context).size.width *
                                          0.035,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      // Parking Location
                      if (widget.request.vehicle.parkingLocation.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height * 0.004),
                          child: Row(
                            children: [
                              Icon(Icons.local_parking,
                                  size:
                                      MediaQuery.of(context).size.width * 0.018,
                                  color: AppColors.primary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: TextComponent(
                                  labelText:
                                      widget.request.vehicle.parkingLocation,
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.014,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01),
                      // Row 2: Time and Requested at
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: MediaQuery.of(context).size.width * 0.016,
                                color: AppColors.error,
                              ),
                              SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      0.008),
                              TextComponent(
                                labelText:
                                    RetrievalRequestUtils.formatWaitingTime(
                                        widget.request.waitingTime),
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.016,
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ],
                          ),
                          TextComponent(
                            labelText:
                                '${t.get(TextConstants.requestedAt)} ${RetrievalRequestUtils.formatTime(widget.request.requestedAt)}',
                            fontSize: MediaQuery.of(context).size.width * 0.014,
                            color: AppColors.mutedText,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01),
                      // Row 3: Requested by name and Phone number
                      Row(
                        children: [
                          TextComponent(
                            labelText: t.get(TextConstants.parkedByLabel),
                            fontSize: MediaQuery.of(context).size.width * 0.014,
                            color: AppColors.mutedText,
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.004,
                          ),
                          TextComponent(
                            labelText: widget.request.parkedBy.name,
                            fontSize: MediaQuery.of(context).size.width * 0.016,
                            color: AppColors.black,
                            fontWeight: FontWeight.w600,
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              final phone = widget.request.parkedBy.phone;
                              if (phone != null && phone.isNotEmpty) {
                                _callPhoneNumber(phone);
                              } else {
                                SnackBars.showErrorSnackBar(
                                    context, 'No phone number available');
                              }
                            },
                            child: Icon(
                              Icons.phone_outlined,
                              size: MediaQuery.of(context).size.width * 0.016,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                      if (widget.request.assignedTo.name.isNotEmpty) ...[
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.01),
                        // Row 3: Requested by name and Phone number
                        Row(
                          children: [
                            TextComponent(
                              labelText: t.get(TextConstants.assignedToLabel),
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.014,
                              color: AppColors.mutedText,
                            ),
                            TextComponent(
                              labelText: widget.request.assignedTo.name,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.016,
                              color: AppColors.black,
                              fontWeight: FontWeight.w600,
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                final phone = widget.request.assignedTo.phone;
                                if (phone.isNotEmpty) {
                                  _callPhoneNumber(phone);
                                } else {
                                  SnackBars.showErrorSnackBar(
                                      context, 'No phone number available');
                                }
                              },
                              child: Icon(
                                Icons.phone_outlined,
                                size: MediaQuery.of(context).size.width * 0.016,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (!_manualDragDropEnabled) {
      return cardBody;
    }

    return DragTarget<AvailableDriver>(
      onWillAcceptWithDetails: (details) {
        if (!_isAssignable) {
          return false;
        }
        // Only accept if driver status is 'free'
        return details.data.status.toLowerCase() == 'free';
      },
      onAcceptWithDetails: (details) {
        if (!_isAssignable) {
          setState(() {
            _isDraggingOver = false;
          });
          return;
        }
        setState(() {
          _isDraggingOver = false;
        });
        _showAssignmentDialog(details.data);
      },
      onMove: (details) {
        if (_isAssignable && !_isDraggingOver) {
          setState(() {
            _isDraggingOver = true;
          });
        }
      },
      onLeave: (data) {
        setState(() {
          _isDraggingOver = false;
        });
      },
      builder: (context, candidateData, rejectedData) => cardBody,
    );
  }
}
