import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:evalet/bloc/oauth/login/outlet_location_retry_cubit.dart';
import 'package:evalet/bloc/oauth/login/outlet_location_retry_state.dart';
import 'package:evalet/bloc/scanner/scanner_menu/scanner_menu_bloc.dart';
import 'package:evalet/bloc/scanner/scanner_menu/scanner_menu_event.dart';
import 'package:evalet/bloc/scanner/scanner_menu/scanner_menu_state.dart';
import 'package:evalet/bloc/websocket/websocket_bloc.dart';
import 'package:evalet/bloc/driver/driver_home/driver_menu_bloc.dart';
import 'package:evalet/bloc/driver/driver_home/driver_menu_event.dart';
import 'package:evalet/bloc/driver/driver_home/driver_menu_state.dart';
import 'package:evalet/models/oauth/profile.dart';
import 'package:evalet/models/outlet/outlet.dart';
import 'package:evalet/ui/common/widgets/snack_bar.dart';
import 'package:evalet/ui/driver/driver_home/status/clock_in_too_far_screen.dart';
import 'package:evalet/ui/driver/driver_home/widgets/pre_break_info_dialog.dart';
import 'package:evalet/ui/guidelines/guidelines_screen.dart';
import 'package:evalet/ui/help_support/help_screen.dart';
import 'package:evalet/ui/oauth/login/login_role_navigation.dart';
import 'package:evalet/ui/oauth/profile/profile_screen.dart';

/// How [LoginOutletTooFarPage] re-checks location when the user taps Retry.
enum LoginOutletTooFarRetryMode {
  driverClockIn,
  outletVerify,
}

/// Full-screen gate after login when clock-in / verify-location reports the user is too far.
/// Provides Retry (fresh GPS + API) without logging out again.
class LoginOutletTooFarPage extends StatelessWidget {
  final Profile profile;
  final String initialDetailMessage;
  final LoginOutletTooFarRetryMode retryMode;

  /// Required when [retryMode] is [LoginOutletTooFarRetryMode.driverClockIn].
  final Outlet? driverOutlet;

  /// Required when [retryMode] is [LoginOutletTooFarRetryMode.outletVerify].
  final int? verifyOutletId;

  final bool scannerMode;
  final bool operatorStyleMenus;

  /// Replaces stack with login (provided by caller to avoid importing [LoginScreen] here).
  final void Function(BuildContext context) onLogoutPushLogin;

  const LoginOutletTooFarPage({
    super.key,
    required this.profile,
    required this.initialDetailMessage,
    required this.retryMode,
    this.driverOutlet,
    this.verifyOutletId,
    required this.scannerMode,
    required this.operatorStyleMenus,
    required this.onLogoutPushLogin,
  }) : assert(
          retryMode != LoginOutletTooFarRetryMode.driverClockIn ||
              driverOutlet != null,
          'driverOutlet is required for driverClockIn retries',
        ),
        assert(
          retryMode != LoginOutletTooFarRetryMode.outletVerify ||
              verifyOutletId != null,
          'verifyOutletId is required for outletVerify retries',
        );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => OutletLocationRetryCubit(
        initialMessage: initialDetailMessage,
        webSocketBloc: ctx.read<WebSocketBloc>(),
      ),
      child: BlocConsumer<OutletLocationRetryCubit, OutletLocationRetryState>(
        listenWhen: (previous, current) =>
            current is OutletLocationRetrySuccess ||
            current is OutletLocationRetryTransientFailure,
        listener: (context, state) {
          if (state is OutletLocationRetrySuccess) {
            navigateToHomeForAuthenticatedProfile(context, state.profile);
          } else if (state is OutletLocationRetryTransientFailure) {
            SnackBars.showErrorSnackBar(context, state.notification);
            context.read<OutletLocationRetryCubit>().acknowledgeTransientFailure();
          }
        },
        builder: (context, retryState) {
          final message = retryState.displayMessage;

          VoidCallback onRetryPressed;
          switch (retryMode) {
            case LoginOutletTooFarRetryMode.driverClockIn:
              final outlet = driverOutlet!;
              onRetryPressed = () => context
                  .read<OutletLocationRetryCubit>()
                  .retryDriverClockIn(profile: profile, outlet: outlet);
              break;
            case LoginOutletTooFarRetryMode.outletVerify:
              final oid = verifyOutletId!;
              onRetryPressed = () => context
                  .read<OutletLocationRetryCubit>()
                  .retryOutletVerify(profile: profile, outletId: oid);
              break;
          }

          final screen = ClockInTooFarScreen(
            scannerMode: scannerMode,
            message: message,
            onRetryPressed: onRetryPressed,
            isRetryBusy: retryState.isBusy,
          );

          if (scannerMode) {
            return BlocProvider<ScannerMenuBloc>(
              create: (_) => ScannerMenuBloc(),
              child: BlocListener<ScannerMenuBloc, ScannerMenuState>(
                listener: (ctx, menuState) {
                  if (menuState is ScannerMenuLogoutSuccess) {
                    SnackBars.showSuccessSnackBar(
                      ctx,
                      menuState.response.message,
                    );
                    onLogoutPushLogin(ctx);
                    ctx.read<ScannerMenuBloc>().add(const ScannerMenuReset());
                  } else if (menuState is ScannerMenuLogoutFailure) {
                    SnackBars.showErrorSnackBar(ctx, menuState.message);
                    onLogoutPushLogin(ctx);
                    ctx.read<ScannerMenuBloc>().add(const ScannerMenuReset());
                  } else if (menuState is ScannerMenuAction) {
                    if (menuState.action == ScannerMenuActionType.profile) {
                      Navigator.of(ctx).push(
                        MaterialPageRoute(
                          builder: (__) => const ProfileScreen(),
                        ),
                      );
                      ctx.read<ScannerMenuBloc>().add(const ScannerMenuReset());
                    }
                  }
                },
                child: screen,
              ),
            );
          }

          return BlocProvider<DriverMenuBloc>(
            create: (_) => DriverMenuBloc(),
            child: BlocListener<DriverMenuBloc, DriverMenuState>(
              listener: (ctx, menuState) {
                if (menuState is DriverMenuLogoutSuccess) {
                  SnackBars.showSuccessSnackBar(
                    ctx,
                    menuState.response.message,
                  );
                  onLogoutPushLogin(ctx);
                  ctx.read<DriverMenuBloc>().add(const DriverMenuReset());
                } else if (menuState is DriverMenuLogoutFailure) {
                  SnackBars.showErrorSnackBar(ctx, menuState.message);
                  onLogoutPushLogin(ctx);
                  ctx.read<DriverMenuBloc>().add(const DriverMenuReset());
                } else if (menuState is DriverMenuLogoutBlockedByPendingWork) {
                  PreBreakInfoDialog.show(
                    ctx,
                    title: 'Cannot Logout',
                    actionLabel: 'logout',
                    info: menuState.preBreakInfo,
                  ).then((selectedDriver) {
                    if (!ctx.mounted || selectedDriver == null) return;
                    ctx.read<DriverMenuBloc>().add(const DriverLogoutPressed());
                  });
                } else if (menuState is DriverMenuAction) {
                  switch (menuState.action) {
                    case DriverMenuActionType.profile:
                      Navigator.of(ctx).push(
                        MaterialPageRoute(
                          builder: (__) => const ProfileScreen(),
                        ),
                      );
                      ctx.read<DriverMenuBloc>().add(const DriverMenuReset());
                      break;
                    case DriverMenuActionType.guidelines:
                      Navigator.of(ctx).push(
                        MaterialPageRoute(
                          builder: (__) => GuidelinesScreen(
                            isOperatorGuidelines: operatorStyleMenus,
                          ),
                        ),
                      );
                      ctx.read<DriverMenuBloc>().add(const DriverMenuReset());
                      break;
                    case DriverMenuActionType.help:
                      Navigator.of(ctx).push(
                        MaterialPageRoute(
                          builder: (__) => HelpScreen(
                            isFromOperator: operatorStyleMenus,
                          ),
                        ),
                      );
                      ctx.read<DriverMenuBloc>().add(const DriverMenuReset());
                      break;
                    case DriverMenuActionType.logout:
                      break;
                  }
                }
              },
              child: screen,
            ),
          );
        },
      ),
    );
  }
}
