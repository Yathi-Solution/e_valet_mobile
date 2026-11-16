import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:evalet/services/operator/driver_groups_repository.dart';
import 'package:evalet/bloc/operator/operator_home/operator_menu_bloc.dart';
import 'package:evalet/bloc/operator/operator_home/operator_menu_event.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/operator/operator_grouping/driver_group.dart';
import 'package:evalet/models/operator/operator_grouping/driver_group_member.dart';
import 'package:evalet/models/operator/operator_valet/valet_response.dart';
import 'package:evalet/services/translations/app_translations_notifier.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/text_constants.dart';
import 'package:evalet/ui/common/widgets/custom_app_bar.dart';
import 'package:evalet/ui/common/widgets/snack_bar.dart';
import 'package:evalet/ui/common/widgets/text.dart';
import 'package:evalet/ui/guidelines/guidelines_screen.dart';
import 'package:evalet/ui/help_support/help_screen.dart';
import 'package:evalet/ui/oauth/profile/profile_screen.dart';
import 'package:evalet/ui/operator/operator_drawer/operator_drawer.dart';
import 'package:evalet/ui/operator/operator_drawer/operator_logout_scope.dart';
import 'package:evalet/ui/operator/operator_grouping/widgets/grouping_add_group_dialog.dart';
import 'package:evalet/ui/operator/operator_overtime/operator_overtime_screen.dart';
import 'package:evalet/ui/operator/operator_grouping/widgets/grouping_add_members_dialog.dart';
import 'package:evalet/ui/operator/operator_grouping/widgets/grouping_group_list_card.dart';
import 'package:provider/provider.dart';

class OperatorGroupingScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;

  const OperatorGroupingScreen({super.key, this.onNavigateToTab});

  @override
  State<OperatorGroupingScreen> createState() => _OperatorGroupingScreenState();
}

class _OperatorGroupingScreenState extends State<OperatorGroupingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String _outletId = dotenv.env['OUTLET_ID'] ?? '1';
  Future<List<DriverGroup>>? _groupsFuture;
  final Map<int, Future<List<DriverGroupMember>>> _membersFuturesByGroupId = {};
  Future<List<ValetResponse>>? _valetsFuture;
  final OperatorMenuBloc _menuBloc = OperatorMenuBloc();

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _menuBloc.close();
    super.dispose();
  }

  void _loadGroups() {
    setState(() {
      _groupsFuture = DriverGroupsRepository.groups(outletId: _outletId);
      _membersFuturesByGroupId.clear();
      _valetsFuture = null;
    });
  }

  void _loadValetsIfNeeded() {
    _valetsFuture ??= DriverGroupsRepository.valets(outletId: _outletId);
  }

  void _reloadValets() {
    setState(() {
      _valetsFuture = DriverGroupsRepository.valets(outletId: _outletId);
    });
  }

  Future<void> _showAddMembersDialog({
    required int groupId,
    required String groupName,
  }) async {
    final t = context.read<AppTranslationsNotifier>();
    await GroupingAddMembersDialog.show(
      context: context,
      t: t,
      outletId: _outletId,
      groupId: groupId,
      groupName: groupName,
      valetsFutureGetter: () => _valetsFuture,
      ensureValetsLoaded: _loadValetsIfNeeded,
      reloadValets: _reloadValets,
      onMembersAdded: (gid) {
        setState(() {
          _membersFuturesByGroupId[gid] = DriverGroupsRepository.members(
            outletId: _outletId,
            groupId: gid,
          );
        });
      },
    );
  }

  Future<void> _showAddGroupDialog() async {
    final t = context.read<AppTranslationsNotifier>();
    await GroupingAddGroupDialog.show(
      context: context,
      t: t,
      outletId: _outletId,
      valetsFutureGetter: () => _valetsFuture,
      ensureValetsLoaded: _loadValetsIfNeeded,
      reloadValets: _reloadValets,
      onGroupCreated: _loadGroups,
    );
  }

  Future<void> _removeMemberFromGroup({
    required int groupId,
    required DriverGroupMember member,
  }) async {
    final t = context.read<AppTranslationsNotifier>();
    final shouldRemove = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
              contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: TextComponent(
                labelText: t.getByKey('removeMember', 'Remove member'),
                color: AppColors.black,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
              content: TextComponent(
                labelText: t.getByKey(
                  'removeMemberConfirm',
                  'Are you sure you want to remove this driver from this group?',
                ),
                color: AppColors.mutedText,
                fontSize: 16,
                maxLines: 4,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(110, 46),
                  ),
                  child: TextComponent(
                    labelText: t.getByKey('cancel', 'Cancel'),
                    color: AppColors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size(120, 46),
                  ),
                  child: TextComponent(
                    labelText: t.getByKey('remove', 'Remove'),
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldRemove) return;

    try {
      await DriverGroupsRepository.removeMember(
        outletId: _outletId,
        groupId: groupId,
        driverUserId: member.driverUserId,
      );

      if (!mounted) return;
      _loadGroups();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextComponent(
            labelText: t.getByKey(
              'memberRemoved',
              'Driver removed from group',
            ),
            color: AppColors.white,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      SnackBars.showErrorSnackBar(context, getDisplayErrorMessage(e));
    }
  }

  /// Return to operator dashboard tab 0. When this screen was opened on top of
  /// other routes (e.g. Overtime → Drivers Group), a single [Navigator.pop] would
  /// reveal Overtime again; pop until the post-login root matches overtime back behavior.
  void _goToDashboard() {
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab?.call(0);
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    Navigator.of(context).pop();
  }

  void _onMenuItemSelected(int index) {
    if (index == 9) {
      return;
    }

    if (index == 4) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OperatorOverTimeScreen(
            onNavigateToTab: widget.onNavigateToTab,
          ),
        ),
      );
      return;
    }

    if (index == 5) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
      return;
    }

    if (index == 6) {
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => const HelpScreen(isFromOperator: true)),
      );
      return;
    }

    if (index == 7) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const GuidelinesScreen(isOperatorGuidelines: true),
        ),
      );
      return;
    }

    if (index == 8) {
      _menuBloc.add(const OperatorMenuLogoutRequested());
      return;
    }

    if ((index >= 0 && index <= 3) || index == 10) {
      if (widget.onNavigateToTab != null) {
        widget.onNavigateToTab?.call(index);
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Makes Logout in the drawer work from this screen.
    return OperatorLogoutScope(bloc: _menuBloc, child: _buildScreen(context));
  }

  Widget _buildScreen(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final width = MediaQuery.of(context).size.width;
    final isAndroidPhone = !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        width < 600;

    final headerTitleFontSize =
        isAndroidPhone ? (width * 0.05).clamp(18.0, 22.0) : (width * 0.03);
    final headerDescriptionFontSize =
        isAndroidPhone ? (width * 0.038).clamp(14.0, 16.0) : (width * 0.02);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _goToDashboard();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.primarySurface,
        endDrawer: OperatorDrawer(
          selectedIndex: 9,
          onItemSelected: _onMenuItemSelected,
        ),
        appBar: CustomAppBar(
          showLanguageIcon: true,
          actions: [
            IconButton(
              onPressed: _loadGroups,
              icon: const Icon(Icons.refresh, color: AppColors.white),
            ),
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.white),
              onPressed: () {
                final currentScope = FocusScope.of(context);
                if (!currentScope.hasPrimaryFocus &&
                    currentScope.focusedChild != null) {
                  currentScope.unfocus();
                }
                _scaffoldKey.currentState?.openEndDrawer();
              },
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(width * 0.02),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: AppColors.black,
                      onPressed: _goToDashboard,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextComponent(
                          labelText: t.getByKey(
                            TextConstants.i18nKeyDriversGroup,
                            TextConstants.driversGroup,
                          ),
                          color: AppColors.black,
                          fontSize: headerTitleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 4),
                        TextComponent(
                          labelText: t.getFirstTranslation(
                            [
                              TextConstants.i18nKeyDriversGroupSubtitle,
                              TextConstants.i18nKeyGroupingDescription,
                            ],
                            TextConstants.driversGroupSubtitle,
                          ),
                          color: AppColors.mutedText,
                          fontSize: headerDescriptionFontSize,
                        ),
                      ],
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _showAddGroupDialog,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      icon: Icon(
                        Icons.add_circle_outline,
                        size: (headerTitleFontSize * 1.2).clamp(22.0, 28.0),
                      ),
                      label: TextComponent(
                        labelText: t.getFirstTranslation(
                          [
                            TextConstants.i18nKeyAddGroupLabel,
                            TextConstants.i18nKeyAddGroup,
                          ],
                          TextConstants.addGroupLabel,
                        ),
                        color: AppColors.primary,
                        fontSize: headerTitleFontSize,
                        fontWeight: FontWeight.bold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FutureBuilder<List<DriverGroup>>(
                  future: _groupsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextComponent(
                                labelText: t.getByKey(
                                  'groupingLoadFailed',
                                  'Failed to load groups',
                                ),
                                color: AppColors.error,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              TextComponent(
                                labelText:
                                    getDisplayErrorMessage(snapshot.error),
                                color: AppColors.mutedText,
                                fontSize: 12,
                                textAlign: TextAlign.center,
                                maxLines: 4,
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: _loadGroups,
                                child: TextComponent(
                                  labelText: t.getByKey('retry', 'Retry'),
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final groups = snapshot.data ?? [];
                    if (groups.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: TextComponent(
                            labelText: t.getByKey(
                              'groupingNoGroups',
                              'No groups found',
                            ),
                            color: AppColors.mutedText,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        for (final g in groups)
                          GroupingGroupListCard(
                            group: g,
                            t: t,
                            membersFuture: _membersFuturesByGroupId.putIfAbsent(
                              g.id,
                              () => DriverGroupsRepository.members(
                                outletId: _outletId,
                                groupId: g.id,
                              ),
                            ),
                            onAddMembers: () => _showAddMembersDialog(
                              groupId: g.id,
                              groupName: g.name,
                            ),
                            onRetryMembers: () {
                              setState(() {
                                _membersFuturesByGroupId[g.id] =
                                    DriverGroupsRepository.members(
                                  outletId: _outletId,
                                  groupId: g.id,
                                );
                              });
                            },
                            onRemoveMember: (member) => _removeMemberFromGroup(
                              groupId: g.id,
                              member: member,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
