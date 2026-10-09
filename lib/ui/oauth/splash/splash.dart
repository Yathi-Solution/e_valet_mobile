import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/splash/splash_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/splash/splash_event.dart';
import 'package:niloufer_valet_mobile/bloc/splash/splash_state.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/version/version_check_args.dart';
import 'package:niloufer_valet_mobile/ui/version/version_check_screen.dart';

/// Startup bootstrap (translations, auth). Splash animation is disabled for now.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _authCheckStarted = false;

  @override
  void initState() {
    super.initState();
    context.read<SplashBloc>().add(const SplashStarted());
  }

  void _runAuthCheck() {
    if (_authCheckStarted) return;
    _authCheckStarted = true;
    context.read<SplashBloc>().add(const SplashAnimationCompleted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashBloc, SplashState>(
      listener: (context, state) {
        if (state is SplashLoaded) {
          _runAuthCheck();
        }
        if (state is SplashCompleted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VersionCheckScreen(
                args: VersionCheckArgs(
                  isAuthenticated: state.isAuthenticated,
                  roles: state.roles,
                ),
              ),
            ),
          );
        }
      },
      child: BlocBuilder<SplashBloc, SplashState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.headerDark,
            body: state is SplashError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        TextComponent(
                          labelText: state.message,
                          fontSize: 16,
                          color: AppColors.error,
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
