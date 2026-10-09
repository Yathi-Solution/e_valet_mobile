import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/utils/duration_utils.dart';

/// Overtime confirmation dialog: shows selected time in hours+minutes.
/// Shows Cancel and Confirm; on Confirm calls [onConfirm].
/// Backend key [overtimeConfirmMessage] expects template with {valetName} and {minutes}.
/// We replace {minutes} with a human readable "X hours Y minutes" string.
class OvertimeConfirmDialog {
  OvertimeConfirmDialog._();

  static String _formatOvertimeConfirmMessage(
    AppTranslationsNotifier t,
    String valetName,
    int extraMinutes,
  ) {
    final template = t.getByKey(
      'overtimeConfirmMessage',
      TextConstants.overtimeConfirmMessage(valetName, extraMinutes),
    );
    final duration = DurationUtils.formatHoursMinutes(t, extraMinutes);

    var formatted = template
        .replaceAll('{valetName}', valetName)
        .replaceAll('{minutes}', duration);

    // Some backends may return an already-interpolated message like:
    // "You have extended X time 125 more." (without `{minutes}` placeholder).
    // In that case, replace the raw numeric value with the formatted duration.
    if (!template.contains('{minutes}')) {
      formatted = formatted.replaceAll(extraMinutes.toString(), duration);
    }

    return formatted;
  }

  static void show(
    BuildContext context, {
    required String driverUserId,
    required int extraMinutes,
    required String valetName,
    required VoidCallback onConfirm,
  }) {
    final t = context.read<AppTranslationsNotifier>();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: TextComponent(
          labelText: t.getByKey(
              'overtimeConfirmTitle', TextConstants.overtimeConfirmTitle),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
        content: TextComponent(
          labelText: _formatOvertimeConfirmMessage(
            t,
            valetName,
            extraMinutes,
          ),
          fontSize: 16,
          color: AppColors.black,
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.mutedText,
              side: BorderSide(color: AppColors.grey.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: TextComponent(
              labelText: t.get(TextConstants.cancelText),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.mutedText,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: TextComponent(
              labelText: t.get(TextConstants.confirm),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
