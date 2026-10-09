import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:niloufer_valet_mobile/api/operator/operator_grouping/operator_driver_groups_api_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_grouping/driver_group_member.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/custom_app_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/guidelines/guidelines_screen.dart';
import 'package:niloufer_valet_mobile/ui/help_support/help_screen.dart';
import 'package:niloufer_valet_mobile/ui/oauth/profile/profile_screen.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_drawer/operator_drawer.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_overtime/operator_overtime_screen.dart';
import 'package:provider/provider.dart';

class OperatorGroupMembersScreen extends StatefulWidget {
  final int groupId;
  final ValueChanged<int>? onNavigateToTab;

  /// Optional: pass groupName from list screen for instant header.
  final String? groupName;

  const OperatorGroupMembersScreen({
    super.key,
    required this.groupId,
    this.onNavigateToTab,
    this.groupName,
  });

  @override
  State<OperatorGroupMembersScreen> createState() =>
      _OperatorGroupMembersScreenState();
}

class _OperatorGroupMembersScreenState
    extends State<OperatorGroupMembersScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String _outletId = dotenv.env['OUTLET_ID'] ?? '1';

  Future<({String groupName, List<DriverGroupMember> members})>? _future;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() {
    setState(() {
      _future = OperatorDriverGroupsApiService.getDriverGroupMembers(
        outletId: _outletId,
        groupId: widget.groupId,
      ).then((res) => (groupName: res.groupName, members: res.members));
    });
  }

  void _onMenuItemSelected(int index) {
    if (index == 9) {
      // Grouping is a separate area; return to Grouping list by popping.
      Navigator.of(context).pop();
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
      Navigator.of(context).pop();
      return;
    }

    if ((index >= 0 && index <= 3) || index == 10) {
      if (widget.onNavigateToTab != null) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        widget.onNavigateToTab?.call(index);
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final width = MediaQuery.of(context).size.width;
    final isAndroidPhone = !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        width < 600;

    final headerTitleFontSize =
        isAndroidPhone ? (width * 0.05).clamp(18.0, 22.0) : (width * 0.03);
    final headerDescriptionFontSize =
        isAndroidPhone ? (width * 0.038).clamp(14.0, 16.0) : (width * 0.02);

    return Scaffold(
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
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: _loadMembers,
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
          child: FutureBuilder<
              ({String groupName, List<DriverGroupMember> members})>(
            future: _future,
            builder: (context, snapshot) {
              final resolvedGroupName = snapshot.data?.groupName ??
                  widget.groupName ??
                  t.getByKey('groupMembersTitle', 'Group Members');

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        color: AppColors.black,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextComponent(
                            labelText: resolvedGroupName,
                            color: AppColors.black,
                            fontSize: headerTitleFontSize,
                            fontWeight: FontWeight.bold,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          TextComponent(
                            labelText: t.getByKey(
                              'groupMembersDescription',
                              'View members in this group',
                            ),
                            color: AppColors.mutedText,
                            fontSize: headerDescriptionFontSize,
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (snapshot.hasError)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextComponent(
                              labelText: t.getByKey(
                                'groupMembersLoadFailed',
                                'Failed to load group members',
                              ),
                              color: AppColors.error,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            TextComponent(
                              labelText: getDisplayErrorMessage(snapshot.error),
                              color: AppColors.mutedText,
                              fontSize: 12,
                              textAlign: TextAlign.center,
                              maxLines: 4,
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _loadMembers,
                              child: TextComponent(
                                labelText: t.getByKey('retry', 'Retry'),
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Builder(
                      builder: (context) {
                        final members = snapshot.data?.members ?? [];
                        if (members.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: TextComponent(
                                labelText: t.getByKey(
                                  'groupMembersEmpty',
                                  'No members found',
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
                            for (final m in members)
                              Card(
                                elevation: 1,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.12),
                                    child: TextComponent(
                                      labelText: (m.name.isNotEmpty
                                              ? m.name.trim()[0]
                                              : '?')
                                          .toUpperCase(),
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  title: TextComponent(
                                    labelText: m.name.isEmpty ? '—' : m.name,
                                    color: AppColors.black,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 2),
                                      TextComponent(
                                        labelText: m.phone,
                                        color: AppColors.mutedText,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      TextComponent(
                                        labelText:
                                            '${t.getByKey('joinedAt', 'Joined at')}: ${m.joinedAt}',
                                        color: AppColors.mutedText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
