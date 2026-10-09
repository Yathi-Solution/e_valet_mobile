import 'package:flutter/material.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';

/// Section header with icon and accent styling.
class GuidelinesSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;

  static const _languageHeaders = {'English', 'हिंदी', 'తెలుగు'};

  const GuidelinesSection({
    super.key,
    required this.title,
    required this.items,
    this.icon = Icons.info_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accentSoft,
                AppColors.accentSoft.withOpacity(0.6),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: AppColors.accent.withOpacity(0.4), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextComponent(
                  labelText: title,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.nearBlack,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...items.map((item) {
          final isLanguageHeader = _languageHeaders.contains(item);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextComponent(
              labelText: item,
              fontSize: 14,
              fontWeight: isLanguageHeader ? FontWeight.bold : FontWeight.w400,
              color: isLanguageHeader ? AppColors.primaryDark : AppColors.black,
              textDecoration:
                  isLanguageHeader ? TextDecoration.underline : null,
              textDecorationThickness: isLanguageHeader ? 2.0 : null,
              textDecorationColor:
                  isLanguageHeader ? AppColors.primaryDark : null,
            ),
          );
        }),
      ],
    );
  }
}
