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

class GroupingAddGroupDialog {
  GroupingAddGroupDialog._();

  static Future<void> show({
    required BuildContext context,
    required AppTranslationsNotifier t,
    required String outletId,
    required Future<List<ValetResponse>>? Function() valetsFutureGetter,
    required VoidCallback ensureValetsLoaded,
    required VoidCallback reloadValets,
    required VoidCallback onGroupCreated,
  }) async {
    ensureValetsLoaded();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _GroupingAddGroupDialogBody(
        t: t,
        outletId: outletId,
        valetsFutureGetter: valetsFutureGetter,
        reloadValets: reloadValets,
        onGroupCreated: onGroupCreated,
      ),
    );
  }
}

class _GroupingAddGroupDialogBody extends StatefulWidget {
  const _GroupingAddGroupDialogBody({
    required this.t,
    required this.outletId,
    required this.valetsFutureGetter,
    required this.reloadValets,
    required this.onGroupCreated,
  });

  final AppTranslationsNotifier t;
  final String outletId;
  final Future<List<ValetResponse>>? Function() valetsFutureGetter;
  final VoidCallback reloadValets;
  final VoidCallback onGroupCreated;

  @override
  State<_GroupingAddGroupDialogBody> createState() =>
      _GroupingAddGroupDialogBodyState();
}

class _GroupingAddGroupDialogBodyState
    extends State<_GroupingAddGroupDialogBody> {
  late final TextEditingController _nameController;
  final List<ValetResponse> _selectedValets = [];
  Future<Set<String>>? _assignedDriverIdsFuture;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _assignedDriverIdsFuture =
        OperatorDriverGroupsApiService.getAssignedDriverUserIds(
      outletId: widget.outletId,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = widget.t;
    final groupName = _nameController.text.trim();
    if (groupName.isEmpty) {
      setState(() {
        _errorText = t.getByKey(
          'groupNameRequired',
          'Please enter group name',
        );
      });
      return;
    }
    if (_selectedValets.isEmpty) {
      setState(() {
        _errorText = t.getByKey(
          'groupMembersRequired',
          'Please select at least one member',
        );
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    try {
      final created = await OperatorDriverGroupsApiService.createDriverGroup(
        outletId: widget.outletId,
        name: groupName,
      );

      for (final v in _selectedValets) {
        await OperatorDriverGroupsApiService.addDriverGroupMember(
          outletId: widget.outletId,
          groupId: created.id,
          request: AddGroupMemberRequest(driverUserId: v.userId),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onGroupCreated();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = getDisplayErrorMessage(e);
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Dialog(
      backgroundColor: AppColors.primarySurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth:
              (MediaQuery.of(context).size.width * 0.9).clamp(280.0, 420.0),
          maxHeight:
              (MediaQuery.of(context).size.height * 0.62).clamp(260.0, 460.0),
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
                      labelText: t.getFirstTranslation(
                        [
                          TextConstants.i18nKeyAddGroupLabel,
                          TextConstants.i18nKeyAddGroup,
                        ],
                        TextConstants.addGroupLabel,
                      ),
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.black),
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
                    TextComponent(
                      labelText: t.getByKey(
                        'groupName',
                        'Group Name',
                      ),
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                      fontSize: 13,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      enabled: !_isSubmitting,
                      decoration: InputDecoration(
                        hintText: t.getByKey(
                          'enterGroupName',
                          'Enter group name',
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GroupingDialogValetField(
                      valetsFutureGetter: widget.valetsFutureGetter,
                      assignedDriverIdsFutureGetter: () =>
                          _assignedDriverIdsFuture,
                      isSubmitting: _isSubmitting,
                      selectedValets: _selectedValets,
                      t: t,
                      reloadValets: widget.reloadValets,
                      setLocalState: (fn) => setState(fn),
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 12),
                      TextComponent(
                        labelText: _errorText!,
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
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
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
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                      child: _isSubmitting
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
  }
}
