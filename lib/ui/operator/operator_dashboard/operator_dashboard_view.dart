import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:evalet/bloc/operator/operator_home/operator_menu_bloc.dart';
import 'package:evalet/bloc/operator/operator_home/operator_menu_event.dart';
import 'package:evalet/bloc/operator/operator_dashboard/operator_dashboard_bloc.dart';
import 'package:evalet/bloc/operator/operator_dashboard/operator_dashboard_event.dart';
import 'package:evalet/bloc/websocket/websocket_bloc.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/guidelines/guidelines_screen.dart';
import 'package:evalet/ui/help_support/help_screen.dart';
import 'package:evalet/ui/common/widgets/custom_app_bar.dart';
import 'package:evalet/ui/oauth/profile/profile_screen.dart';
import 'package:evalet/ui/operator/operator_dashboard/operator_content.dart';
import 'package:evalet/ui/operator/operator_drawer/operator_drawer.dart';
import 'package:evalet/ui/operator/operator_grouping/operator_grouping_screen.dart';
import 'package:evalet/ui/operator/operator_overtime/operator_overtime_screen.dart';
import 'package:evalet/api/operator/operator_dashboard/operator_auto_assign_api_service.dart';
import 'operator_screen_router.dart';

class OperatorDashboardView extends StatefulWidget {
  const OperatorDashboardView({super.key});

  @override
  State<OperatorDashboardView> createState() => _OperatorDashboardViewState();
}

class _OperatorDashboardViewState extends State<OperatorDashboardView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  int _refreshKey = 0;
  VoidCallback? _dashboardRefresh;
  VoidCallback? _slotsRefresh;
  VoidCallback? _driversRefresh;
  VoidCallback? _cardsRefresh;
  late OperatorDashboardBloc _dashboardBloc;
  final String _outletId = dotenv.env['OUTLET_ID'] ?? '1';

  /// Auto mode state lifted here so it persists when user switches tabs and comes back.
  bool _isAutoMode = true;

  @override
  void initState() {
    super.initState();
    final webSocketBloc = context.read<WebSocketBloc?>();
    _dashboardBloc = OperatorDashboardBloc(
      webSocketBloc: webSocketBloc,
      outletId: _outletId,
    );
    _dashboardBloc.add(FetchDashboardKpis(outletId: _outletId));

    _ensureAutoAssignEnabled();
  }

  Future<void> _ensureAutoAssignEnabled() async {
    try {
      // Force auto-assign enabled server-side as well (UI toggle is hidden).
      await OperatorAutoAssignApiService.patchAutoAssignSettings(
        outletId: _outletId,
        enabled: true,
      );
    } catch (e) {
      // Keep UI behavior as auto mode even if backend update fails.
    }
  }

  @override
  void dispose() {
    _dashboardBloc.close();
    super.dispose();
  }

  void _onMenuItemSelected(int index) {
    if (index == 8) {
      // Logout
      context.read<OperatorMenuBloc>().add(const OperatorMenuLogoutRequested());
    } else if (index == 4) {
      // Over Time – open separate screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OperatorOverTimeScreen(
            onNavigateToTab: (tabIndex) {
              setState(() => _selectedIndex = tabIndex);
            },
          ),
        ),
      );
    } else if (index == 5) {
      // Profile – navigate to profile screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        ),
      );
    } else if (index == 6) {
      // Help – shared screen for driver and operator
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const HelpScreen(isFromOperator: true),
        ),
      );
    } else if (index == 7) {
      // Operator guidelines – show only Operator Responsibilities
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const GuidelinesScreen(isOperatorGuidelines: true),
        ),
      );
    } else if (index == 9) {
      // Grouping – open separate screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OperatorGroupingScreen(
            onNavigateToTab: (tabIndex) {
              setState(() => _selectedIndex = tabIndex);
            },
          ),
        ),
      );
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  void _refreshDashboard() {
    print(
        '_refreshDashboard called, selectedIndex: $_selectedIndex'); // Debug log
    // Call specific refresh callback based on selected tab
    switch (_selectedIndex) {
      case 0:
        // Dashboard
        print('Calling dashboard refresh'); // Debug log
        _dashboardRefresh?.call();
        break;
      case 1:
        // Slots/Parked Car screen
        print(
            'Calling slots refresh, callback is: ${_slotsRefresh != null ? "set" : "null"}'); // Debug log
        _slotsRefresh?.call();
        break;
      case 2:
        // Drivers/Valets screen
        print(
            'Calling drivers refresh, callback is: ${_driversRefresh != null ? "set" : "null"}'); // Debug log
        _driversRefresh?.call();
        break;
      case 10:
        _cardsRefresh?.call();
        break;
      default:
        // For other tabs (Car Logs), increment refresh key to recreate the widget
        print('Incrementing refresh key for tab $_selectedIndex'); // Debug log
        setState(() {
          _refreshKey++;
        });
    }
  }

  Widget _getBodyWidget() {
    return OperatorScreenRouter.getScreen(
      _selectedIndex,
      DashboardContent(
        isAutoMode: _isAutoMode,
        onAutoModeChanged: null,
        onRefreshReady: (refresh) {
          print('Dashboard refresh callback registered'); // Debug log
          _dashboardRefresh = refresh;
        },
        onNavigateToTab: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      _refreshKey,
      onSlotsRefreshReady: (refresh) {
        print('Slots refresh callback registered'); // Debug log
        _slotsRefresh = refresh;
      },
      onDriversRefreshReady: (refresh) {
        print('Drivers refresh callback registered'); // Debug log
        _driversRefresh = refresh;
      },
      onCardsRefreshReady: (refresh) {
        _cardsRefresh = refresh;
      },
      onNavigateToTab: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      isAutoMode: _isAutoMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    // OperatorMenuBloc and its logout listener live in OperatorDashboardScreen.
    return BlocProvider.value(
      value: _dashboardBloc,
      child: Scaffold(
        key: _scaffoldKey,
        endDrawer: OperatorDrawer(
          selectedIndex: _selectedIndex,
          onItemSelected: _onMenuItemSelected,
        ),
        appBar: CustomAppBar(
          showLanguageIcon: true,
          actions: [
            IconButton(
              onPressed: _refreshDashboard,
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
        body: _getBodyWidget(),
      ),
    );
  }
}
