import 'package:flutter/material.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';

class ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: MediaQuery.of(context).size.width * 0.06,
          color: AppColors.primary,
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.04,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextComponent(
                labelText: label,
                fontSize: MediaQuery.of(context).size.width * 0.03,
                fontWeight: FontWeight.w500,
                color: AppColors.mutedText,
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.01,
              ),
              TextComponent(
                labelText: value,
                fontSize: MediaQuery.of(context).size.width * 0.04,
                fontWeight: FontWeight.w500,
                color: AppColors.black,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
