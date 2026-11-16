import 'package:flutter/material.dart';
import 'package:evalet/ui/operator/operator_drawer/operator_logout_scope.dart';
import 'operator_home_view.dart';

class OperatorHomeScreen extends StatelessWidget {
  const OperatorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const OperatorLogoutScope(child: OperatorHomeView());
  }
}
