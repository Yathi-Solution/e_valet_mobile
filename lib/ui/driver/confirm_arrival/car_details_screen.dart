import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/models/driver/session/assigned_session.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/custom_app_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';

/// Full-screen page showing car/session details (badge, parking location, parked by, call).
class CarDetailsScreen extends StatelessWidget {
  final AssignedSession session;

  const CarDetailsScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBeigeBackground,
      appBar: const CustomAppBar(showOverflowMenu: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: CarDetailsSection(session: session),
        ),
      ),
    );
  }
}

/// Details section: badge number, parking location, parked by + call.
/// Can be embedded in a parent or used inside [CarDetailsScreen].
class CarDetailsSection extends StatelessWidget {
  final AssignedSession session;

  const CarDetailsSection({super.key, required this.session});

  static const double _rowSpacing = 16;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth * 0.045;
    final labelFontSize = screenWidth * 0.045;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: (screenWidth * 0.05).clamp(16.0, 24.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow10,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DetailRow(
                      icon: Icons.confirmation_number_outlined,
                      label: t.get(TextConstants.cardNumber),
                      value: session.cardNumber.toString(),
                      valueBold: true,
                      screenWidth: screenWidth,
                      labelFontSize: labelFontSize,
                      valueFontSize: fontSize,
                    ),
                    if (session.parkingLocation.isNotEmpty) ...[
                      const SizedBox(height: _rowSpacing),
                      _DetailRow(
                        icon: Icons.location_on_outlined,
                        value: session.parkingLocation,
                        maxLines: 3,
                        screenWidth: screenWidth,
                        labelFontSize: labelFontSize,
                        valueFontSize: fontSize,
                      ),
                    ],
                    const SizedBox(height: _rowSpacing),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.person_outline,
                            size: 18, color: AppColors.black),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextComponent(
                            labelText:
                                '${t.get(TextConstants.parkedByLabel)} ${session.parkedBy?.name ?? t.get(TextConstants.unknown)}',
                            fontSize: fontSize,
                            color: AppColors.black,
                            maxLines: 1,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _CallButton(
                          onPressed: () => FlutterPhoneDirectCaller.callNumber(
                              session.parkedBy?.phone ?? ''),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String value;
  final bool valueBold;
  final int maxLines;
  final double screenWidth;
  final double labelFontSize;
  final double valueFontSize;

  const _DetailRow({
    required this.icon,
    this.label,
    required this.value,
    this.valueBold = false,
    this.maxLines = 1,
    required this.screenWidth,
    required this.labelFontSize,
    required this.valueFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 25,
          color: AppColors.black,
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: label != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextComponent(
                      labelText: label!,
                      fontSize: labelFontSize,
                      color: AppColors.black,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: TextComponent(
                        labelText: value,
                        fontSize: valueFontSize,
                        fontWeight:
                            valueBold ? FontWeight.w700 : FontWeight.w500,
                        color: AppColors.black,
                        maxLines: maxLines,
                      ),
                    ),
                  ],
                )
              : TextComponent(
                  labelText: value,
                  fontSize: valueFontSize,
                  color: AppColors.black,
                  maxLines: maxLines,
                  fontWeight: FontWeight.w500,
                ),
        ),
      ],
    );
  }
}

class _CallButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CallButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.phone_outlined, size: 18, color: AppColors.black),
              const SizedBox(width: 4),
              TextComponent(
                labelText: t.getByKey('callButton', TextConstants.callButton),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
