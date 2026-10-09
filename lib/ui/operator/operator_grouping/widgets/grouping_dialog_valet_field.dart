import 'package:flutter/material.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_valet/valet_response.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_grouping/widgets/grouping_valet_picker_sheet.dart';

/// Valet multi-select used inside Add Group / Add Members dialogs.
class GroupingDialogValetField extends StatelessWidget {
  const GroupingDialogValetField({
    super.key,
    required this.valetsFutureGetter,
    required this.isSubmitting,
    required this.selectedValets,
    required this.t,
    required this.reloadValets,
    required this.setLocalState,
    this.assignedDriverIdsFutureGetter,
  });

  final Future<List<ValetResponse>>? Function() valetsFutureGetter;
  final bool isSubmitting;
  final List<ValetResponse> selectedValets;
  final AppTranslationsNotifier t;
  final VoidCallback reloadValets;
  final void Function(VoidCallback fn) setLocalState;
  final Future<Set<String>>? Function()? assignedDriverIdsFutureGetter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextComponent(
          labelText: t.getByKey(
            'groupMembers',
            'Group Members',
          ),
          fontWeight: FontWeight.w600,
          color: AppColors.black,
          fontSize: 13,
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<ValetResponse>>(
          future: valetsFutureGetter(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snap.hasError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextComponent(
                    labelText: t.getByKey(
                      'valetsLoadFailed',
                      'Failed to load valets',
                    ),
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () {
                            reloadValets();
                            setLocalState(() {});
                          },
                    child: TextComponent(
                      labelText: t.getByKey('retry', 'Retry'),
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }

            final allValets = snap.data ?? [];
            if (assignedDriverIdsFutureGetter == null) {
              return _buildPickerContent(context, allValets);
            }

            return FutureBuilder<Set<String>>(
              future: assignedDriverIdsFutureGetter!(),
              builder: (context, assignedSnap) {
                if (assignedSnap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (assignedSnap.hasError) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextComponent(
                        labelText: getDisplayErrorMessage(assignedSnap.error),
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: isSubmitting
                            ? null
                            : () {
                                setLocalState(() {});
                              },
                        child: TextComponent(
                          labelText: t.getByKey('retry', 'Retry'),
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                }

                final assignedIds = assignedSnap.data ?? <String>{};
                final availableValets = allValets
                    .where((v) => !assignedIds.contains(v.userId))
                    .toList();
                return _buildPickerContent(context, availableValets);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPickerContent(
    BuildContext context,
    List<ValetResponse> allValets,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (allValets.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextComponent(
              labelText: t.getByKey(
                'noAvailableMembers',
                'No available drivers',
              ),
              color: AppColors.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
        TextField(
          readOnly: true,
          enabled: !isSubmitting && allValets.isNotEmpty,
          decoration: InputDecoration(
            hintText: t.getByKey(
              'selectMembers',
              'Select members',
            ),
            prefixIcon: const Icon(
              Icons.people,
              color: AppColors.primary,
            ),
            suffixIcon: const Icon(
              Icons.arrow_drop_down,
              color: AppColors.mutedText,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onTap: () async {
            final picked = await showModalBottomSheet<List<ValetResponse>>(
              context: context,
              isScrollControlled: true,
              backgroundColor: AppColors.primarySurface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              builder: (sheetContext) => GroupingValetPickerSheet(
                allValets: allValets,
                initialSelection: List<ValetResponse>.from(selectedValets),
                t: t,
              ),
            );

            if (!context.mounted) return;
            if (picked == null) return;
            setLocalState(() {
              selectedValets
                ..clear()
                ..addAll(picked);
            });
          },
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in selectedValets)
              Chip(
                label: TextComponent(
                  labelText: v.name,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                deleteIcon: const Icon(
                  Icons.close,
                  size: 18,
                ),
                onDeleted: isSubmitting
                    ? null
                    : () {
                        setLocalState(() {
                          selectedValets.removeWhere(
                            (x) => x.userId == v.userId,
                          );
                        });
                      },
              ),
          ],
        ),
      ],
    );
  }
}
