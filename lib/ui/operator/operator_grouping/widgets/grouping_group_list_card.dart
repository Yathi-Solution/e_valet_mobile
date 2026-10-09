import 'package:flutter/material.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_grouping/driver_group.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_grouping/driver_group_member.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';

/// When the API returns names like `Group 1`, swap the English prefix for i18n.
String localizedDriverGroupTitle(String apiName, AppTranslationsNotifier t) {
  final trimmed = apiName.trim();
  final match =
      RegExp(r'^Group\s+(\S+)\s*$', caseSensitive: false).firstMatch(trimmed);
  if (match != null) {
    final prefix = t.getByKey(
      TextConstants.i18nKeyGroupNamePrefix,
      TextConstants.groupNamePrefix,
    );
    return '$prefix ${match.group(1)}';
  }
  return apiName;
}

class GroupingGroupListCard extends StatelessWidget {
  const GroupingGroupListCard({
    super.key,
    required this.group,
    required this.t,
    required this.membersFuture,
    required this.onAddMembers,
    required this.onRetryMembers,
    required this.onRemoveMember,
  });

  final DriverGroup group;
  final AppTranslationsNotifier t;
  final Future<List<DriverGroupMember>> membersFuture;
  final VoidCallback onAddMembers;
  final VoidCallback onRetryMembers;
  final Future<void> Function(DriverGroupMember member) onRemoveMember;

  @override
  Widget build(BuildContext context) {
    final g = group;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextComponent(
                        labelText: localizedDriverGroupTitle(g.name, t),
                        color: AppColors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      TextComponent(
                        labelText:
                            '${t.getByKey(TextConstants.i18nKeyMembers, TextConstants.groupMembersCountLabel)}: ${g.memberCount}',
                        color: AppColors.mutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onAddMembers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: TextComponent(
                    labelText: t.getFirstTranslation(
                      [
                        TextConstants.i18nKeyAddMembersLabel,
                        TextConstants.i18nKeyAddMembers,
                      ],
                      TextConstants.addMembersLabel,
                    ),
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(
              color: AppColors.grey.withValues(alpha: 0.2),
              thickness: 1,
              height: 1,
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<DriverGroupMember>>(
              future: membersFuture,
              builder: (context, membersSnap) {
                if (membersSnap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (membersSnap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextComponent(
                          labelText: t.getByKey(
                            'groupMembersLoadFailed',
                            'Failed to load group members',
                          ),
                          color: AppColors.error,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        const SizedBox(height: 6),
                        TextComponent(
                          labelText: getDisplayErrorMessage(membersSnap.error),
                          color: AppColors.mutedText,
                          fontSize: 12,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: onRetryMembers,
                            child: TextComponent(
                              labelText: t.getByKey(
                                'retry',
                                'Retry',
                              ),
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final members = membersSnap.data ?? [];
                if (members.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextComponent(
                      labelText: t.getByKey(
                        'groupMembersEmpty',
                        'No members found',
                      ),
                      color: AppColors.mutedText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }

                return Column(
                  children: [
                    for (final m in members)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.12),
                              child: TextComponent(
                                labelText:
                                    (m.name.isNotEmpty ? m.name.trim()[0] : '?')
                                        .toUpperCase(),
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextComponent(
                                    labelText: m.name.isEmpty ? '—' : m.name,
                                    color: AppColors.black,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  TextComponent(
                                    labelText: m.phone,
                                    color: AppColors.mutedText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: t.getByKey(
                                'remove',
                                'Remove',
                              ),
                              onPressed: () => onRemoveMember(m),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primarySurface,
                                foregroundColor: AppColors.error,
                                padding: const EdgeInsets.all(8),
                                minimumSize: const Size(40, 40),
                                side: BorderSide(
                                  color: AppColors.error.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 24,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
