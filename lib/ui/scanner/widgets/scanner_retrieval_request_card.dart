import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/retrieval_request.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/full_image_viewer_dialog.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/utils/retrieval_request_utils.dart';

/// Read-only card for a single retrieval request on the scanner home screen.
/// Shows card number, status, vehicle, waiting time, requested at, parked by, assigned to.
class ScannerRetrievalRequestCard extends StatelessWidget {
  const ScannerRetrievalRequestCard({
    super.key,
    required this.request,
  });

  final RetrievalRequest request;

  Color _statusColor() => RetrievalRequestUtils.getStatusColor(
        status: request.status,
        waitingTime: request.waitingTime,
      );

  String _statusLabel() => RetrievalRequestUtils.getStatusLabel(
        status: request.status,
        waitingTime: request.waitingTime,
      );

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final size = MediaQuery.of(context).size;

    return Container(
      margin: EdgeInsets.only(
        bottom: size.height * 0.012,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.03,
        vertical: size.height * 0.012,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _statusColor(),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: request.vehicle.photo.isNotEmpty
                ? () => FullImageViewerDialog.show(
                      context,
                      request.vehicle.photo,
                    )
                : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: request.vehicle.photo.isNotEmpty
                  ? Image.network(
                      request.vehicle.photo,
                      width: size.width * 0.2,
                      height: size.width * 0.2,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _vehiclePlaceholder(size),
                    )
                  : _vehiclePlaceholder(size),
            ),
          ),
          SizedBox(width: size.width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextComponent(
                      labelText: t.getByKey(
                        TextConstants.cardNumberWithHash(
                          request.cardNumber,
                        ),
                      ),
                      fontSize: size.width * 0.04,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.02,
                        vertical: size.height * 0.004,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextComponent(
                        labelText: _statusLabel(),
                        fontSize: size.width * 0.03,
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (request.vehicle.parkingLocation.isNotEmpty) ...[
                  SizedBox(height: size.height * 0.004),
                  Row(
                    children: [
                      Icon(
                        Icons.local_parking,
                        size: size.width * 0.035,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextComponent(
                          labelText: request.vehicle.parkingLocation,
                          fontSize: size.width * 0.032,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: size.height * 0.008),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: size.width * 0.035,
                          color: AppColors.error,
                        ),
                        SizedBox(
                          width: size.width * 0.01,
                        ),
                        TextComponent(
                          labelText: request.waitingTime,
                          fontSize: size.width * 0.032,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                    TextComponent(
                      labelText:
                          '${t.get(TextConstants.requestedAt)} ${RetrievalRequestUtils.formatTime(request.requestedAt)}',
                      fontSize: size.width * 0.03,
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.006),
                Row(
                  children: [
                    TextComponent(
                      labelText: '${t.get(TextConstants.parkedByLabel)} ',
                      fontSize: size.width * 0.03,
                      color: AppColors.mutedText,
                    ),
                    TextComponent(
                      labelText: request.parkedBy.name,
                      fontSize: size.width * 0.032,
                      color: AppColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
                if (request.assignedTo.name.isNotEmpty) ...[
                  SizedBox(height: size.height * 0.004),
                  Row(
                    children: [
                      TextComponent(
                        labelText: '${t.get(TextConstants.assignedToLabel)} ',
                        fontSize: size.width * 0.03,
                        color: AppColors.mutedText,
                      ),
                      TextComponent(
                        labelText: request.assignedTo.name,
                        fontSize: size.width * 0.032,
                        color: AppColors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vehiclePlaceholder(Size size) {
    return Container(
      width: size.width * 0.2,
      height: size.width * 0.2,
      color: AppColors.grey.withOpacity(0.3),
      child: Icon(
        Icons.directions_car,
        size: size.width * 0.08,
        color: AppColors.mutedText,
      ),
    );
  }
}
