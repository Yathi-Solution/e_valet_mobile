import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:evalet/bloc/operator/operator_home/operator_menu_bloc.dart';
import 'package:evalet/bloc/operator/operator_home/operator_menu_state.dart';
import 'package:evalet/ui/common/widgets/snack_bar.dart';
import 'package:evalet/ui/oauth/login/login.dart';

/// Provides an [OperatorMenuBloc] to [child] and sends the user to the login
/// screen once logout finishes (successfully or not).
///
/// Every operator screen that has the drawer wraps itself in this so Logout
/// works from that screen. Pass [bloc] when the screen owns the bloc (it needs
/// to add the logout event from its State); otherwise one is created here.
class OperatorLogoutScope extends StatelessWidget {
  final OperatorMenuBloc? bloc;
  final Widget child;

  const OperatorLogoutScope({super.key, this.bloc, required this.child});

  @override
  Widget build(BuildContext context) {
    final listener = BlocListener<OperatorMenuBloc, OperatorMenuState>(
      listener: (context, state) {
        if (state is OperatorMenuLogoutSuccess) {
          SnackBars.showSuccessSnackBar(context, state.message);
        } else if (state is OperatorMenuLogoutFailure) {
          // Local session is cleared even when the API call failed.
          SnackBars.showErrorSnackBar(context, state.message);
        } else {
          return;
        }
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      },
      child: child,
    );

    final existing = bloc;
    if (existing != null) {
      return BlocProvider.value(value: existing, child: listener);
    }
    return BlocProvider(create: (_) => OperatorMenuBloc(), child: listener);
  }
}
