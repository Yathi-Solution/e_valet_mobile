import 'package:flutter/material.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/text_constants.dart';
import 'package:evalet/ui/common/widgets/elevated_button.dart';
import 'package:evalet/ui/common/widgets/text.dart';
import 'package:provider/provider.dart';
import 'package:evalet/services/translations/app_translations_notifier.dart';

/// Full-screen blocker when the app cannot reach the internet (shown above all routes).
class NoInternetOverlay extends StatelessWidget {
  final VoidCallback onRetry;

  const NoInternetOverlay({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();

    return Material(
      color: AppColors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 80,
                color: AppColors.primary.withValues(alpha: 0.85),
              ),
              const SizedBox(height: 24),
              TextComponent(
                labelText: t.get(TextConstants.noInternetConnection),
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextComponent(
                labelText: t.get(TextConstants.noInternetConnectionHint),
                fontSize: 15,
                color: AppColors.black.withValues(alpha: 0.65),
                textAlign: TextAlign.center,
                maxLines: 4,
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButtonComponent(
                  labelText: t.get(TextConstants.retryButton),
                  onPressed: onRetry,
                  elevatedButtonBackgroundColor: AppColors.primary,
                  fontColor: AppColors.white,
                  radius: 10,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
