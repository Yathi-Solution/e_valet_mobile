import 'package:flutter/material.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';

class KpiCard extends StatelessWidget {
  final String title;
  final String value;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextComponent(
            labelText: title,
            textAlign: TextAlign.center,
            color: AppColors.black,
            fontSize: MediaQuery.of(context).size.height * 0.012,
            fontWeight: FontWeight.w400,
          ),
          const SizedBox(
            height: 8,
          ),
          TextComponent(
            labelText: value,
            textAlign: TextAlign.center,
            color: AppColors.black,
            fontSize: MediaQuery.of(context).size.height * 0.015,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }
}
