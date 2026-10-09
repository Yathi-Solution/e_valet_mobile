import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/car_logs_kpis_response.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/skeleton_loader.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_dashboard/widgets/kpi_card.dart';

class CarLogsKpiGrid extends StatelessWidget {
  final CarLogsKpisResponse? kpis;
  final bool isLoading;

  const CarLogsKpiGrid({
    super.key,
    this.kpis,
    this.isLoading = false,
  });

  Widget _buildKpiSkeletonCard(BuildContext context) {
    return Expanded(
      child: Container(
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
            SkeletonLoader(
              height: MediaQuery.of(context).size.height * 0.012,
              width: MediaQuery.of(context).size.width * 0.12,
              borderRadius: 4,
            ),
            const SizedBox(height: 8),
            SkeletonLoader(
              height: MediaQuery.of(context).size.height * 0.015,
              width: MediaQuery.of(context).size.width * 0.08,
              borderRadius: 4,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    if (isLoading) {
      return Row(
        children: [
          _buildKpiSkeletonCard(context),
          const SizedBox(width: 12),
          _buildKpiSkeletonCard(context),
          const SizedBox(width: 12),
          _buildKpiSkeletonCard(context),
          const SizedBox(width: 12),
          _buildKpiSkeletonCard(context),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: KpiCard(
            title: t.getByKey(
              'carLogsKpiTotalParked',
              TextConstants.carLogsKpiTotalParked,
            ),
            value: kpis != null ? '${kpis!.totalCarsParked}' : '0',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: KpiCard(
            title: t.getByKey(
              'carLogsKpiInTransit',
              TextConstants.carLogsKpiInTransit,
            ),
            value: kpis != null ? '${kpis!.carsInTransit}' : '0',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: KpiCard(
            title: t.getByKey(
              'carLogsKpiHandovered',
              TextConstants.carLogsKpiHandovered,
            ),
            value: kpis != null ? '${kpis!.carsHandovered}' : '0',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: KpiCard(
            title: t.getByKey(
              'carLogsKpiInLot',
              TextConstants.carLogsKpiInLot,
            ),
            value: kpis != null ? '${kpis!.carsInLot}' : '0',
          ),
        ),
      ],
    );
  }
}
