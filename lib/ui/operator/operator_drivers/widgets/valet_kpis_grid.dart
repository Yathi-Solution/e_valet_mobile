import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:evalet/models/operator/operator_valet/valet_kpis_response.dart';
import 'package:evalet/services/translations/app_translations_notifier.dart';
import 'package:evalet/ui/common/text_constants.dart';
import 'package:evalet/ui/operator/operator_drivers/widgets/valet_kpi_card.dart';
import 'package:evalet/ui/operator/operator_drivers/operator_drivers_screen.dart';

class ValetKpisGrid extends StatelessWidget {
  final ValetKpisResponse? kpis;
  final bool isLoading;
  final ValetFilter selectedFilter;
  final Function(ValetFilter) onFilterChanged;

  const ValetKpisGrid({
    super.key,
    this.kpis,
    this.isLoading = false,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    // Same compact row layout as dashboard KPIs
    return Row(
      children: [
        Expanded(
          child: ValetKpiCard(
            value: kpis != null ? '${kpis!.totalValets}' : '0',
            label: t.get(TextConstants.totalValets),
            isLoading: isLoading,
            isSelected: selectedFilter == ValetFilter.all,
            onTap: () => onFilterChanged(ValetFilter.all),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ValetKpiCard(
            value: kpis != null ? '${kpis!.availableValets}' : '0',
            label: t.get(TextConstants.onavailableValets),
            isLoading: isLoading,
            isSelected: selectedFilter == ValetFilter.available,
            onTap: () => onFilterChanged(ValetFilter.available),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ValetKpiCard(
            value: kpis != null ? '${kpis!.onDutyValets}' : '0',
            label: t.getByKey('onDutyValets', TextConstants.onDutyValets),
            isLoading: isLoading,
            isSelected: selectedFilter == ValetFilter.onDuty,
            onTap: () => onFilterChanged(ValetFilter.onDuty),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ValetKpiCard(
            value: kpis != null ? '${kpis!.onBreakValets}' : '0',
            label: t.getByKey('onBreakValets', TextConstants.onBreakValets),
            isLoading: isLoading,
            isSelected: selectedFilter == ValetFilter.onBreak,
            onTap: () => onFilterChanged(ValetFilter.onBreak),
          ),
        ),
      ],
    );
  }
}
