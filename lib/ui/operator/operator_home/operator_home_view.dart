import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:evalet/bloc/operator/operator_home/operator_menu_bloc.dart';
import 'package:evalet/bloc/operator/operator_home/operator_menu_event.dart';
import 'package:evalet/ui/guidelines/guidelines_screen.dart';
import 'package:evalet/ui/help_support/help_screen.dart';
import 'package:evalet/services/translations/app_translations_notifier.dart';
import 'package:evalet/ui/common/text_constants.dart';
import 'package:evalet/ui/common/widgets/text.dart';
import 'package:evalet/ui/oauth/profile/profile_screen.dart';
import 'package:evalet/ui/operator/operator_drawer/operator_drawer.dart';

class OperatorHomeView extends StatefulWidget {
  const OperatorHomeView({super.key});

  @override
  State<OperatorHomeView> createState() => _OperatorHomeViewState();
}

class _OperatorHomeViewState extends State<OperatorHomeView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  void _onMenuItemSelected(int index) {
    if (index == 4) {
      // Profile – navigate to profile screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        ),
      );
    } else if (index == 5) {
      // Help – shared screen for driver and operator
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const HelpScreen(isFromOperator: true),
        ),
      );
    } else if (index == 6) {
      // Operator guidelines – show only Operator Responsibilities
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const GuidelinesScreen(isOperatorGuidelines: true),
        ),
      );
    } else if (index == 7) {
      // Logout
      context.read<OperatorMenuBloc>().add(const OperatorMenuLogoutRequested());
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return Scaffold(
      key: _scaffoldKey,
      drawer: OperatorDrawer(
          selectedIndex: _selectedIndex, onItemSelected: _onMenuItemSelected),
      appBar: AppBar(
        title: TextComponent(
          labelText: t.get(TextConstants.operatorHomeTitle),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // Open the custom drawer (hamburger)
              _scaffoldKey.currentState?.openEndDrawer();
            },
          )
        ],
      ),
      body: Center(
        child: TextComponent(
          labelText: '${t.get(TextConstants.welcomeOperator)} $_selectedIndex',
        ),
      ),
    );
  }
}
