import 'package:flutter/material.dart';
import 'package:evalet/ui/operator/operator_drawer/operator_logout_scope.dart';
import 'operator_dashboard_view.dart';

class OperatorDashboardScreen extends StatelessWidget {
  const OperatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The logout loader is app-wide (LogoutProgressOverlay), not per screen.
    return const OperatorLogoutScope(child: OperatorDashboardView());
  }
}
