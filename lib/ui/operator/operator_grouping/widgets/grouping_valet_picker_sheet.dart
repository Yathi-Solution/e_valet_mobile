import 'package:flutter/material.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_valet/valet_response.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';

/// Bottom sheet content for multi-selecting valets (search + checkboxes).
class GroupingValetPickerSheet extends StatefulWidget {
  const GroupingValetPickerSheet({
    super.key,
    required this.allValets,
    required this.initialSelection,
    required this.t,
  });

  final List<ValetResponse> allValets;
  final List<ValetResponse> initialSelection;
  final AppTranslationsNotifier t;

  @override
  State<GroupingValetPickerSheet> createState() =>
      _GroupingValetPickerSheetState();
}

class _GroupingValetPickerSheetState extends State<GroupingValetPickerSheet> {
  late final TextEditingController _searchController;
  late List<ValetResponse> _filtered;
  late final Set<String> _localSelectedIds;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filtered = List<ValetResponse>.from(widget.allValets);
    _localSelectedIds = {
      for (final v in widget.initialSelection) v.userId,
    };
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    if (!mounted) return;
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List<ValetResponse>.from(widget.allValets);
      } else {
        _filtered = widget.allValets.where((v) {
          return v.name.toLowerCase().contains(q) ||
              v.phone.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height:
              (MediaQuery.of(context).size.height * 0.75).clamp(300.0, 650.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextComponent(
                        labelText: t.getByKey(
                          'selectMembers',
                          'Select members',
                        ),
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: t.getByKey(
                      'searchValets',
                      'Search valets...',
                    ),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (context, idx) {
                    final v = _filtered[idx];
                    final selected = _localSelectedIds.contains(v.userId);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _localSelectedIds.add(v.userId);
                          } else {
                            _localSelectedIds.remove(v.userId);
                          }
                        });
                      },
                      title: TextComponent(
                        labelText: v.name,
                        color: AppColors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      subtitle: TextComponent(
                        labelText: v.phone,
                        color: AppColors.mutedText,
                        fontSize: 12,
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: TextComponent(
                          labelText: t.getByKey('cancel', 'Cancel'),
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                        ),
                        onPressed: () {
                          final picked = widget.allValets
                              .where(
                                  (v) => _localSelectedIds.contains(v.userId))
                              .toList();
                          Navigator.of(context).pop(picked);
                        },
                        child: TextComponent(
                          labelText: t.getByKey('done', 'Done'),
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
