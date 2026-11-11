import 'package:flutter/material.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/widgets/text.dart';

class SimpleDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const SimpleDetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextComponent(
          labelText: label,
          color: AppColors.black,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        TextComponent(
          labelText: value,
          color: AppColors.black,
          fontSize: 16,
        ),
      ],
    );
  }
}
