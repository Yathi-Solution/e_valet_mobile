import 'package:flutter/material.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/widgets/skeleton_loader.dart';

/// Skeleton placeholder for the car logs table (header + data rows).
class CarLogsTableSkeleton extends StatelessWidget {
  static const int _skeletonRowCount = 8;

  const CarLogsTableSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final rowHeight = 48.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: width),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Container(
              width: width,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.grey.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(color: AppColors.grey.withOpacity(0.3)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(flex: 12, child: _cellSkeleton(context, 0.06)),
                  const SizedBox(width: 8),
                  Expanded(flex: 16, child: _cellSkeleton(context, 0.05)),
                  const SizedBox(width: 8),
                  Expanded(flex: 16, child: _cellSkeleton(context, 0.05)),
                  const SizedBox(width: 8),
                  Expanded(flex: 20, child: _cellSkeleton(context, 0.07)),
                  const SizedBox(width: 8),
                  Expanded(flex: 20, child: _cellSkeleton(context, 0.06)),
                  const SizedBox(width: 8),
                  Expanded(flex: 16, child: _cellSkeleton(context, 0.08)),
                  const SizedBox(width: 8),
                  Expanded(flex: 16, child: _cellSkeleton(context, 0.08)),
                ],
              ),
            ),
            // Data rows
            ...List.generate(_skeletonRowCount, (i) {
              return Container(
                width: width,
                height: rowHeight,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: i % 2 == 0
                      ? AppColors.white
                      : AppColors.grey.withOpacity(0.05),
                  border: Border(
                    bottom: BorderSide(color: AppColors.grey.withOpacity(0.3)),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 12, child: _cellSkeleton(context, 0.04)),
                    const SizedBox(width: 8),
                    Expanded(flex: 16, child: _cellSkeleton(context, 0.05)),
                    const SizedBox(width: 8),
                    Expanded(flex: 16, child: _cellSkeleton(context, 0.04)),
                    const SizedBox(width: 8),
                    Expanded(flex: 20, child: _cellSkeleton(context, 0.06)),
                    const SizedBox(width: 8),
                    Expanded(flex: 20, child: _cellSkeleton(context, 0.05)),
                    const SizedBox(width: 8),
                    Expanded(flex: 16, child: _cellSkeleton(context, 0.07)),
                    const SizedBox(width: 8),
                    Expanded(flex: 16, child: _cellSkeleton(context, 0.07)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _cellSkeleton(BuildContext context, double widthFactor) {
    return SkeletonLoader(
      height: MediaQuery.of(context).size.height * 0.018,
      width: MediaQuery.of(context).size.width * widthFactor,
      borderRadius: 4,
    );
  }
}
