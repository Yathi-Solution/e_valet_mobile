import 'package:flutter/material.dart';
import 'package:niloufer_valet_mobile/api/operator/operator_grouping/operator_driver_groups_api_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_grouping/add_group_member_request.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_valet/valet_response.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_grouping/widgets/grouping_dialog_valet_field.dart';

class GroupingAddMembersDialog {
  GroupingAddMembersDialog._();

  static Future<void> show({
    required BuildContext context,
    required AppTranslationsNotifier t,
    required String outletId,
    required int groupId,
    required String groupName,
    required Future<List<ValetResponse>>? Function() valetsFutureGetter,
    required VoidCallback ensureValetsLoaded,
    required VoidCallback reloadValets,
    required void Function(int groupId) onMembersAdded,
  }) async {
    ensureValetsLoaded();

    final selectedValets = <ValetResponse>[];
    final assignedDriverIdsFuture =
        OperatorDriverGroupsApiService.getAssignedDriverUserIds(
      outletId: outletId,
    );
    var isSubmitting = false;
    String? errorText;

    Future<void> submit(
      BuildContext dialogCtx,
      StateSetter setLocalState,
    ) async {
      if (selectedValets.isEmpty) {
        setLocalState(() {
          errorText = t.getByKey(
            'groupMembersRequired',
            'Please select at least one member',
          );
        });
        return;
      }

      setLocalState(() {
        errorText = null;
        isSubmitting = true;
      });

      try {
        for (final v in selectedValets) {
          await OperatorDriverGroupsApiService.addDriverGroupMember(
            outletId: outletId,
            groupId: groupId,
            request: AddGroupMemberRequest(driverUserId: v.userId),
          );
        }

        if (!dialogCtx.mounted) return;
        Navigator.of(dialogCtx).pop();
        onMembersAdded(groupId);
      } catch (e) {
        if (!dialogCtx.mounted) return;
        setLocalState(() {
          errorText = getDisplayErrorMessage(e);
          isSubmitting = false;
        });
      }
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return Dialog(
              backgroundColor: AppColors.primarySurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      (MediaQuery.of(ctx).size.width * 0.9).clamp(280.0, 420.0),
                  maxHeight: (MediaQuery.of(ctx).size.height * 0.55)
                      .clamp(220.0, 420.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextComponent(
                              labelText: '${t.getFirstTranslation([
                                    TextConstants.i18nKeyAddMembersLabel,
                                    TextConstants.i18nKeyAddMembers,
                                  ], TextConstants.addMembersLabel)} - $groupName',
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                              fontSize: 16,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.of(ctx).pop(),
                            icon:
                                const Icon(Icons.close, color: AppColors.black),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GroupingDialogValetField(
                              valetsFutureGetter: valetsFutureGetter,
                              assignedDriverIdsFutureGetter: () =>
                                  assignedDriverIdsFuture,
                              isSubmitting: isSubmitting,
                              selectedValets: selectedValets,
                              t: t,
                              reloadValets: reloadValets,
                              setLocalState: setLocalState,
                            ),
                            if (errorText != null) ...[
                              const SizedBox(height: 12),
                              TextComponent(
                                labelText: errorText!,
                                color: AppColors.error,
                                fontSize: 12,
                                maxLines: 4,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () => Navigator.of(ctx).pop(),
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
                              onPressed: isSubmitting
                                  ? null
                                  : () => submit(dialogCtx, setLocalState),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : TextComponent(
                                      labelText: t.getByKey('submit', 'Submit'),
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
            );
          },
        );
      },
    );
  }
}
