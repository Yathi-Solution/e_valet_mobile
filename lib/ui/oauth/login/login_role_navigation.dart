import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:evalet/bloc/driver/driver_status/driver_status_bloc.dart';
import 'package:evalet/bloc/driver/driver_status/driver_status_event.dart';
import 'package:evalet/models/oauth/profile.dart';
import 'package:evalet/ui/common/widgets/snack_bar.dart';
import 'package:evalet/ui/driver/driver_home/driver_home.dart';
import 'package:evalet/ui/operator/operator_dashboard/operator_dashboard.dart';
import 'package:evalet/ui/scanner/scanner_home.dart';

/// Navigates to the correct home shell after a completed login flow.
void navigateToHomeForAuthenticatedProfile(
  BuildContext context,
  Profile profile,
) {
  final roles = profile.roles.map((r) => r.toLowerCase()).toList();

  if (roles.any((r) => r.contains('scanner'))) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ScannerHomeScreen()),
      (route) => false,
    );
    return;
  }

  if (roles.any((r) => r.contains('operator') || r.contains('admin'))) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OperatorDashboardScreen()),
      (route) => false,
    );
    return;
  }

  if (roles.any((r) => r.contains('driver'))) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
      (route) => false,
    );
    context.read<DriverStatusBloc>().add(const DriverStatusStarted());
    return;
  }

  SnackBars.showErrorSnackBar(
    context,
    'Your account does not have the required permissions to access this application. Please contact your administrator.',
  );
}
