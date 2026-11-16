import 'package:flutter/material.dart';
import 'package:evalet/services/oauth/logout_progress.dart';
import 'package:evalet/ui/common/colors.dart';

/// Dims and blocks the whole app while [LogoutProgress.active] is set.
///
/// Mounted in `MaterialApp.builder`, above the navigator, so the loader shows
/// on whichever screen the user tapped Logout from.
class LogoutProgressOverlay extends StatelessWidget {
  final Widget child;

  const LogoutProgressOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ValueListenableBuilder<bool>(
          valueListenable: LogoutProgress.active,
          builder: (context, active, _) {
            if (!active) return const SizedBox.shrink();
            return Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: Container(
                  color: AppColors.black.withOpacity(0.45),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
