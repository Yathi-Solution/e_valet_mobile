import 'package:flutter/material.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Center(
        child: TextComponent(
          labelText: '${TextConstants.poweredBy} Yathi Solutions',
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: AppColors.mutedText,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
