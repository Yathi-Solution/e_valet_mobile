import 'package:flutter/material.dart';
import 'package:evalet/ui/common/widgets/dotted_line_painter.dart';

class DottedDivider extends StatelessWidget {
  const DottedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DottedLinePainter(),
      child: const SizedBox(height: 1, width: double.infinity),
    );
  }
}
