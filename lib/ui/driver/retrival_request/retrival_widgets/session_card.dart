import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/models/driver/session/assigned_session.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/full_image_viewer_dialog.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';

class SessionCard extends StatelessWidget {
  final AssignedSession session;
  final VoidCallback? onAccept;

  const SessionCard({super.key, required this.session, this.onAccept});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow10,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Details Section (above image) — spacing OUTSIDE via margin
              Container(
                margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                padding: EdgeInsets.symmetric(vertical: screenWidth * 0.028),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_car,
                          size: screenWidth * 0.045,
                          color: AppColors.secondary,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        TextComponent(
                          labelText: t.get(TextConstants.cardNumber),
                          fontSize: screenWidth * 0.028,
                          color: AppColors.mutedText,
                        ),
                        Spacer(),
                        TextComponent(
                          labelText: session.cardNumber.toString(),
                          fontSize: screenWidth * 0.038,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ],
                    ),
                    SizedBox(height: screenWidth * 0.02),
                    Divider(
                      color: AppColors.greyLight,
                      thickness: 1,
                      height: 1,
                    ),
                    // Show location if available
                    if (session.parkingLocation.isNotEmpty) ...[
                      SizedBox(height: screenWidth * 0.018),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: screenWidth * 0.04,
                            color: AppColors.secondary,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Expanded(
                            child: TextComponent(
                              labelText: session.parkingLocation,
                              fontSize: screenWidth * 0.032,
                              color: AppColors.black,
                              maxLines: 2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenWidth * 0.025),
                      Divider(
                        color: AppColors.greyLight,
                        thickness: 1,
                        height: 1,
                      ),
                    ],
                    SizedBox(height: screenWidth * 0.02),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.badge,
                              size: screenWidth * 0.045,
                              color: AppColors.secondary,
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Expanded(
                              child: TextComponent(
                                labelText:
                                    '${t.get(TextConstants.parkedBy)} ${session.parkedBy?.name ?? t.get(TextConstants.unknown)}',
                                fontSize: screenWidth * 0.032,
                                color: AppColors.black,
                                maxLines: 2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            InkWell(
                              onTap: () =>
                                  _makePhoneCall(session.parkedBy?.phone ?? ''),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: EdgeInsets.all(screenWidth * 0.02),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.phone,
                                  color: AppColors.secondary,
                                  size: screenWidth * 0.045,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Car Image (below details) — tappable to view full size
              GestureDetector(
                onTap: session.photoUrl != null && session.photoUrl!.isNotEmpty
                    ? () =>
                        FullImageViewerDialog.show(context, session.photoUrl!)
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.black,
                      width: 2,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(18),
                    ),
                    color: AppColors.white,
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(18)),
                    child: session.photoUrl != null
                        ? Image.network(
                            session.photoUrl!,
                            key: ValueKey<String>(session.photoUrl!),
                            gaplessPlayback: true,
                            width: double.infinity,
                            height: screenWidth * 0.42,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: screenWidth * 0.42,
                                color: AppColors.white,
                                child: Center(
                                  child: ColorFiltered(
                                    colorFilter: const ColorFilter.matrix([
                                      -1, 0, 0, 0, 255, // Red channel inverted
                                      0, -1, 0, 0,
                                      255, // Green channel inverted
                                      0, 0, -1, 0, 255, // Blue channel inverted
                                      0, 0, 0, 1, 0, // Alpha channel unchanged
                                    ]),
                                    child: Image.asset(
                                      'assets/images/cars.png',
                                      fit: BoxFit.contain,
                                      width: screenWidth * 0.3,
                                      height: screenWidth * 0.3,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            width: double.infinity,
                            height: screenWidth * 0.42,
                            color: AppColors.white,
                            child: Center(
                              child: ColorFiltered(
                                colorFilter: const ColorFilter.matrix([
                                  -1, 0, 0, 0, 255, // Red channel inverted
                                  0, -1, 0, 0, 255, // Green channel inverted
                                  0, 0, -1, 0, 255, // Blue channel inverted
                                  0, 0, 0, 1, 0, // Alpha channel unchanged
                                ]),
                                child: Image.asset(
                                  'assets/images/cars.png',
                                  fit: BoxFit.contain,
                                  width: screenWidth * 0.3,
                                  height: screenWidth * 0.3,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    await FlutterPhoneDirectCaller.callNumber(phoneNumber);
  }
}
