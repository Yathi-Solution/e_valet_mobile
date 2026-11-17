import 'package:flutter/material.dart';
import 'package:evalet/ui/common/colors.dart';

/// Dims the screen and swallows taps while an action is in progress.
class ActionBlockingLoader extends StatelessWidget {
  const ActionBlockingLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: AppColors.black.withOpacity(0.45),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
      ),
    );
  }
}
