import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_valet/valet_response.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/utils/time_utils.dart';
import 'package:niloufer_valet_mobile/utils/valet_utils.dart';

/// Full valet details in a dialog. Close via X button or tap outside.
class ValetDetailsDialog extends StatelessWidget {
  const ValetDetailsDialog({
    super.key,
    required this.valet,
    this.onClose,
    this.onLogoutValet,
  });

  final ValetResponse valet;
  final VoidCallback? onClose;

  /// Called when operator taps "Log out" for this valet. Only shown when status is available, on-duty, or break (not offline).
  final void Function(ValetResponse valet)? onLogoutValet;

  static Future<void> show(
    BuildContext context,
    ValetResponse valet, {
    void Function(ValetResponse valet)? onLogoutValet,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ValetDetailsDialog(
        valet: valet,
        onClose: () => Navigator.of(context).pop(),
        onLogoutValet: onLogoutValet,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    final padding = media.padding;
    final maxW = (screenWidth * 0.9).clamp(280.0, 400.0);
    // Cap content height so dialog can be short when data is short; scroll only when needed
    final maxContentHeight = (screenHeight * 0.5).clamp(200.0, 400.0);

    return Dialog(
      backgroundColor: AppColors.primarySurface,
      insetPadding: EdgeInsets.only(
        left: padding.left + 16,
        right: padding.right + 16,
        top: padding.top + 24,
        bottom: padding.bottom + 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title row with close button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextComponent(
                      labelText: valet.name,
                      fontSize: (screenWidth * 0.04).clamp(14.0, 17.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: onClose ?? () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.black),
                    tooltip: t.get(TextConstants.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content: height fits data, scrolls only if exceeds cap
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxContentHeight),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(label: t.get('Name'), value: valet.name),
                    const SizedBox(height: 12),
                    _DetailRow(label: t.get('Phone'), value: valet.phone),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: t.get(TextConstants.statusLabel),
                      value: ValetUtils.translatedStatusLabel(valet.status, t),
                      valueColor: ValetUtils.getStatusColor(valet.status),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: t.get(TextConstants.carsPickedUpLabel),
                      value: '${valet.carsPickedUp}',
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: t.get(TextConstants.carsHandedOverLabel),
                      value: '${valet.carsHandedOver}',
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: t.get(TextConstants.onBreakDurationLabel),
                      value:
                          '${valet.onBreakDurationMinutes}${t.get(TextConstants.minsLabel)}',
                    ),
                    const SizedBox(height: 12),
                    if (valet.clockInAt.isNotEmpty) ...[
                      _DetailRow(
                        label: t.get(TextConstants.clockInAtLabel),
                        value: TimeUtils.formatUtcToIstFullDateTime(
                            valet.clockInAt),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (valet.clockOutAt.isNotEmpty) ...[
                      _DetailRow(
                        label: t.get(TextConstants.clockOutAtLabel),
                        value: TimeUtils.formatUtcToIstFullDateTime(
                            valet.clockOutAt),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (valet.lastActivity.isNotEmpty) ...[
                      _DetailRow(
                        label: t.get(TextConstants.lastActivityLabel),
                        value: _formatLastActivity(valet.lastActivity),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Logout: show only when status is available / on duty / on break; hide when offline
            if (ValetUtils.isOnline(valet.status) && onLogoutValet != null) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onLogoutValet!(valet);
                      },
                      icon: const Icon(Icons.logout,
                          size: 22, color: AppColors.error),
                      label: TextComponent(
                        labelText: t.get(TextConstants.logout),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatLastActivity(String raw) {
    try {
      return TimeUtils.formatUtcToIstFullDateTime(raw);
    } catch (_) {
      return raw;
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final labelWidth = (width * 0.35).clamp(100.0, 160.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: TextComponent(
            labelText: label,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.mutedText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextComponent(
            labelText: value,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: valueColor ?? AppColors.black,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
