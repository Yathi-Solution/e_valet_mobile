import 'package:flutter/material.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/widgets/text.dart';

class StatusDetailRow extends StatelessWidget {
  final String label;
  final String selectedStatus;
  final List<String> statusOptions;
  final Function(String) onStatusChanged;

  const StatusDetailRow({
    super.key,
    required this.label,
    required this.selectedStatus,
    required this.statusOptions,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: TextComponent(
            labelText: label,
            color: AppColors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minWidth: 100),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                border: InputBorder.none,
              ),
              items: statusOptions.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: TextComponent(
                    labelText: status,
                    fontSize: 14,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onStatusChanged(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
