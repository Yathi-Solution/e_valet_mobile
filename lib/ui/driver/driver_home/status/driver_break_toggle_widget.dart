import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_status/driver_status_bloc.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_status/driver_status_event.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_status/driver_status_state.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';

class DriverBreakToggleWidget extends StatelessWidget {
  final double screenWidth;
  final bool isTablet;
  final bool isDesktop;

  const DriverBreakToggleWidget({
    super.key,
    required this.screenWidth,
    required this.isTablet,
    required this.isDesktop,
  });

  double get _labelFontSize => isDesktop
      ? screenWidth * 0.012
      : isTablet
          ? screenWidth * 0.02
          : screenWidth * 0.035;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return BlocBuilder<DriverStatusBloc, DriverStatusState>(
      builder: (context, statusState) {
        final isOnBreak = statusState is DriverStatusLoaded
            ? statusState.status.isOnBreak
            : statusState is DriverBreakToggleLoading
                ? statusState.previousStatus?.isOnBreak ?? false
                : false;

        final isLoading = statusState is DriverStatusLoading ||
            statusState is DriverBreakToggleLoading;

        final label = isOnBreak
            ? t.getByKey('onBreakScreen', TextConstants.headerOnBreak)
            : t.getByKey(
                TextConstants.i18nKeyAvailable, TextConstants.availableLabel);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: TextComponent(
                key: ValueKey<String>(label),
                labelText: label,
                fontSize: _labelFontSize,
                fontWeight: FontWeight.w400,
                color: AppColors.white,
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            isLoading
                ? SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                : Semantics(
                    button: true,
                    label: isOnBreak ? 'On break, tap to go available' : 'Available, tap to go on break',
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: _BreakToggle(
                          value: isOnBreak,
                          onChanged: (value) {
                            context.read<DriverStatusBloc>().add(
                                  DriverBreakToggled(value),
                                );
                          },
                        ),
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }
}

class _BreakToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _BreakToggle({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const trackWidth = 48.0;
    const trackHeight = 28.0;
    const thumbSize = 22.0;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: trackWidth,
        height: trackHeight,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? AppColors.coral : AppColors.trackGray,
          borderRadius: BorderRadius.circular(trackHeight / 2),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: thumbSize,
            height: thumbSize,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
