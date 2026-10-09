import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_status/driver_status_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_status/driver_status_state.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';

class DriverStatusCardWidget extends StatelessWidget {
  final bool isOnline;
  final double screenWidth;
  final bool isTablet;
  final bool isDesktop;

  const DriverStatusCardWidget({
    super.key,
    required this.isOnline,
    required this.screenWidth,
    required this.isTablet,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return BlocBuilder<DriverStatusBloc, DriverStatusState>(
      builder: (context, statusState) {
        // Get online status from API, fallback to prop if not loaded yet.
        // Online/offline is driven by login/logout; no toggle.
        final onlineStatus = statusState is DriverStatusLoaded
            ? statusState.status.isOnline
            : isOnline;
        return Center(
          child: Container(
            width: (267 * screenWidth / 360).clamp(267.0, screenWidth * 0.9),
            height: (40.3 * MediaQuery.of(context).size.height / 800)
                .clamp(40.3, 57.0),
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: 0,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.power_settings_new,
                        color: AppColors.black,
                        size: isDesktop
                            ? screenWidth * 0.015
                            : isTablet
                                ? screenWidth * 0.025
                                : screenWidth * 0.045,
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      TextComponent(
                        labelText: t.get(TextConstants.statusLabel),
                        fontSize: isDesktop
                            ? screenWidth * 0.014
                            : isTablet
                                ? screenWidth * 0.022
                                : screenWidth * 0.038,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black,
                      ),
                    ],
                  ),
                  TextComponent(
                    labelText: onlineStatus
                        ? t.get(TextConstants.statusOnline)
                        : t.get(TextConstants.statusOffline),
                    fontSize: isDesktop
                        ? screenWidth * 0.014
                        : isTablet
                            ? screenWidth * 0.022
                            : screenWidth * 0.038,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
