import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/button_metrics.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/countdown_cta_button.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
class HandoverButtonsSection extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onConfirmHandover;
  final Future<void> Function()? onCustomerMissing;
  final DateTime? customerMissingDisabledUntil;
  final DateTime? confirmHandoverDisabledUntil;

  const HandoverButtonsSection({
    super.key,
    required this.isLoading,
    required this.onConfirmHandover,
    this.onCustomerMissing,
    this.customerMissingDisabledUntil,
    this.confirmHandoverDisabledUntil,
  });

  @override
  State<HandoverButtonsSection> createState() => HandoverButtonsSectionState();
}

class HandoverButtonsSectionState extends State<HandoverButtonsSection> {
  Key _customerMissingKey = UniqueKey();
  bool _isCustomerMissingLoading = false;
  int _customerMissingRemainingSeconds = 0;
  Timer? _customerMissingCountdownTimer;
  int _confirmHandoverRemainingSeconds = 0;
  Timer? _confirmHandoverCountdownTimer;

  void resetCustomerMissingButton() {
    setState(() => _customerMissingKey = UniqueKey());
  }

  int _remainingSeconds(DateTime? until) {
    if (until == null) return 0;
    final sec = until.difference(DateTime.now()).inSeconds;
    return sec > 0 ? sec : 0;
  }

  void _startCountdownIfNeeded() {
    _customerMissingCountdownTimer?.cancel();
    final remaining = _remainingSeconds(widget.customerMissingDisabledUntil);
    if (remaining <= 0) {
      if (_customerMissingRemainingSeconds != 0) {
        setState(() => _customerMissingRemainingSeconds = 0);
      }
      return;
    }
    setState(() => _customerMissingRemainingSeconds = remaining);
    _customerMissingCountdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;
        final r = _remainingSeconds(widget.customerMissingDisabledUntil);
        if (r <= 0) {
          _customerMissingCountdownTimer?.cancel();
          _customerMissingCountdownTimer = null;
          setState(() => _customerMissingRemainingSeconds = 0);
          return;
        }
        setState(() => _customerMissingRemainingSeconds = r);
      },
    );
  }

  void _startConfirmHandoverCountdownIfNeeded() {
    _confirmHandoverCountdownTimer?.cancel();
    final remaining = _remainingSeconds(widget.confirmHandoverDisabledUntil);
    if (remaining <= 0) {
      if (_confirmHandoverRemainingSeconds != 0) {
        setState(() => _confirmHandoverRemainingSeconds = 0);
      }
      return;
    }
    setState(() => _confirmHandoverRemainingSeconds = remaining);
    _confirmHandoverCountdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;
        final r = _remainingSeconds(widget.confirmHandoverDisabledUntil);
        if (r <= 0) {
          _confirmHandoverCountdownTimer?.cancel();
          _confirmHandoverCountdownTimer = null;
          setState(() => _confirmHandoverRemainingSeconds = 0);
          return;
        }
        setState(() => _confirmHandoverRemainingSeconds = r);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _startCountdownIfNeeded();
    _startConfirmHandoverCountdownIfNeeded();
  }

  @override
  void didUpdateWidget(HandoverButtonsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customerMissingDisabledUntil !=
        widget.customerMissingDisabledUntil) {
      _startCountdownIfNeeded();
    }
    if (oldWidget.confirmHandoverDisabledUntil !=
        widget.confirmHandoverDisabledUntil) {
      _startConfirmHandoverCountdownIfNeeded();
    }
  }

  @override
  void dispose() {
    _customerMissingCountdownTimer?.cancel();
    _confirmHandoverCountdownTimer?.cancel();
    super.dispose();
  }

  Widget _dangerButton({
    Key? key,
    required String label,
    required bool isLoading,
    required VoidCallback? onPressed,
    required int countdownSeconds,
  }) {
    final disabled = countdownSeconds > 0;
    return Builder(
      builder: (context) {
        final fontSize = ButtonMetrics.confirmBigFontSize(context);
        return SizedBox(
          key: key,
          width: double.infinity,
          height: ButtonMetrics.confirmHeight(context),
          child: ElevatedButton(
            onPressed: (isLoading || disabled) ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.error.withValues(alpha: 0.7),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(ButtonMetrics.confirmRadius),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: ButtonMetrics.countdownBadgeSize,
                    height: ButtonMetrics.countdownBadgeSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (disabled)
                        CountdownCtaButton.countdownBadge(countdownSeconds)
                      else
                        const Icon(Icons.warning,
                            color: AppColors.white, size: 26),
                      const SizedBox(width: 12),
                      Flexible(
                        child: TextComponent(
                          labelText: label,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CountdownCtaButton(
                label: t.get(TextConstants.slideToConfirmHandover),
                onPressed: widget.onConfirmHandover,
                isLoading: widget.isLoading &&
                    _confirmHandoverRemainingSeconds <= 0,
                countdownSeconds: _confirmHandoverRemainingSeconds,
                iconWhenEnabled: Icons.handshake,
                height: constraints.maxHeight,
                useBigFont: true,
              );
            },
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        _dangerButton(
          key: _customerMissingKey,
          label: t.get(TextConstants.slideToCustomerMissing),
          isLoading: _isCustomerMissingLoading,
          countdownSeconds: _customerMissingRemainingSeconds,
          onPressed: () async {
            if (_isCustomerMissingLoading) return;
            final onCustomerMissing = widget.onCustomerMissing;
            if (onCustomerMissing == null) return;
            setState(() => _isCustomerMissingLoading = true);
            try {
              await onCustomerMissing();
            } finally {
              if (mounted) setState(() => _isCustomerMissingLoading = false);
            }
          },
        ),
      ],
    );
  }
}
