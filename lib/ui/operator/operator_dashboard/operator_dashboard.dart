import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:evalet/bloc/operator/operator_home/operator_menu_bloc.dart';
import 'package:evalet/bloc/operator/operator_home/operator_menu_state.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/widgets/snack_bar.dart';
import 'package:evalet/ui/oauth/login/login.dart';
import 'operator_dashboard_view.dart';

class OperatorDashboardScreen extends StatelessWidget {
  const OperatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OperatorMenuBloc(),
      child: BlocListener<OperatorMenuBloc, OperatorMenuState>(
        listener: (context, state) {
          if (state is OperatorMenuLogoutSuccess) {
            SnackBars.showSuccessSnackBar(context, state.message);
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          } else if (state is OperatorMenuLogoutFailure) {
            SnackBars.showErrorSnackBar(context, state.message);
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        child: BlocBuilder<OperatorMenuBloc, OperatorMenuState>(
          buildWhen: (previous, current) =>
              (previous is OperatorMenuLogoutLoading) !=
              (current is OperatorMenuLogoutLoading),
          builder: (context, state) {
            return Stack(
              children: [
                const OperatorDashboardView(),
                // Block the screen while logout runs so the tap has visible
                // feedback and cannot be repeated.
                if (state is OperatorMenuLogoutLoading)
                  Positioned.fill(
                    child: AbsorbPointer(
                      absorbing: true,
                      child: Container(
                        color: AppColors.black.withOpacity(0.45),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
