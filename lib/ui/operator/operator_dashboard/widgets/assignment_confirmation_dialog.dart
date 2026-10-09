import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/available_drivers.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/retrieval_request.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/full_image_viewer_dialog.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/utils/driver_utils.dart';

class AssignmentConfirmationDialog extends StatelessWidget {
  final AvailableDriver driver;
  final RetrievalRequest request;
  final VoidCallback onConfirm;

  const AssignmentConfirmationDialog({
    super.key,
    required this.driver,
    required this.request,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.28,
        padding: EdgeInsets.all(
          MediaQuery.of(context).size.width * 0.02,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.01,
                    ),
                    TextComponent(
                      labelText: t.get(TextConstants.confirmAssignment),
                      fontSize: MediaQuery.of(context).size.width * 0.015,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  iconSize: MediaQuery.of(context).size.width * 0.02,
                  color: AppColors.mutedText,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),

            // Driver Details Section
            Container(
              padding: EdgeInsets.all(
                MediaQuery.of(context).size.width * 0.015,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: MediaQuery.of(context).size.width * 0.028,
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                        child: TextComponent(
                          labelText: DriverUtils.getInitials(driver.name),
                          fontSize: MediaQuery.of(context).size.width * 0.016,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(
                          width: MediaQuery.of(context).size.width * 0.015),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextComponent(
                              labelText: driver.name,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.016,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.004),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  size:
                                      MediaQuery.of(context).size.width * 0.014,
                                  color: AppColors.mutedText,
                                ),
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.006),
                                TextComponent(
                                  labelText: driver.phone,
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.014,
                                  color: AppColors.mutedText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.018),

            // Vehicle Details Section
            Container(
              padding: EdgeInsets.all(
                MediaQuery.of(context).size.width * 0.015,
              ),
              decoration: BoxDecoration(
                color: AppColors.grey.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: request.vehicle.photo.isNotEmpty
                        ? () => FullImageViewerDialog.show(
                              context,
                              request.vehicle.photo,
                            )
                        : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: request.vehicle.photo.isNotEmpty
                          ? Image.network(
                              request.vehicle.photo,
                              width: MediaQuery.of(context).size.width * 0.08,
                              height: MediaQuery.of(context).size.width * 0.06,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.08,
                                  height:
                                      MediaQuery.of(context).size.width * 0.06,
                                  decoration: BoxDecoration(
                                    color: AppColors.grey.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.directions_car,
                                    size: MediaQuery.of(context).size.width *
                                        0.035,
                                    color: AppColors.mutedText,
                                  ),
                                );
                              },
                            )
                          : Container(
                              width: MediaQuery.of(context).size.width * 0.08,
                              height: MediaQuery.of(context).size.width * 0.06,
                              decoration: BoxDecoration(
                                color: AppColors.grey.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.directions_car,
                                size: MediaQuery.of(context).size.width * 0.035,
                                color: AppColors.mutedText,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.015),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextComponent(
                          labelText: t.get(TextConstants.cardNumberLabel),
                          fontSize: MediaQuery.of(context).size.width * 0.012,
                          color: AppColors.mutedText,
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.003),
                        TextComponent(
                          labelText:
                              '#${t.get(TextConstants.cardNumber)} ${request.cardNumber}',
                          fontSize: MediaQuery.of(context).size.width * 0.018,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.025),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.height * 0.018,
                      ),
                      side: BorderSide(color: AppColors.mutedText, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: TextComponent(
                      labelText: t.get(TextConstants.cancelText),
                      fontSize: MediaQuery.of(context).size.width * 0.016,
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.height * 0.018,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: MediaQuery.of(context).size.width * 0.018,
                          color: AppColors.white,
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.01),
                        TextComponent(
                          labelText: t.get(TextConstants.confirm),
                          fontSize: MediaQuery.of(context).size.width * 0.016,
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
