import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:evalet/bloc/driver/driver_status/driver_status_bloc.dart';
import 'package:evalet/bloc/driver/driver_status/driver_status_state.dart';
import 'package:evalet/services/translations/app_translations_notifier.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/widgets/text.dart';
import 'package:evalet/ui/common/text_constants.dart';

class DriverOnlineToggleWidget extends StatelessWidget {
  final bool isOnline;
  final double screenWidth;
  final bool isTablet;
  final bool isDesktop;

  const DriverOnlineToggleWidget({
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

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextComponent(
              labelText: onlineStatus
                  ? t.get(TextConstants.statusOnline)
                  : t.get(TextConstants.statusOffline),
              fontSize: isDesktop
                  ? screenWidth * 0.012
                  : isTablet
                      ? screenWidth * 0.02
                      : screenWidth * 0.035,
              fontWeight: FontWeight.w400,
              color: AppColors.white,
            ),
          ],
        );
      },
    );
  }
}
