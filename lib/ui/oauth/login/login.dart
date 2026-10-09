import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/oauth/login/login_event.dart';
import 'package:niloufer_valet_mobile/bloc/websocket/websocket_bloc.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/bloc/oauth/login/login_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/oauth/login/login_state.dart';
import 'package:niloufer_valet_mobile/services/notification/firebase_messaging_service.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/custom_app_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/footer.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';
import 'package:niloufer_valet_mobile/ui/oauth/login/login_form.dart';
import 'package:niloufer_valet_mobile/ui/oauth/login/login_outlet_too_far_page.dart';
import 'package:niloufer_valet_mobile/ui/oauth/login/login_role_navigation.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/outlet_selection_dialog.dart';
import 'package:niloufer_valet_mobile/models/oauth/profile.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.initialSuccessMessage,
  });

  /// Optional one-time message to show when landing on login (e.g. after
  /// deactivating an account). Kept nullable so other flows are unchanged.
  final String? initialSuccessMessage;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _loginIdController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _loginIdFocusNode = FocusNode();
  final FocusNode _pinFocusNode = FocusNode();

  bool _outletDialogShowing = false;
  bool _initialMessageShown = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_initialMessageShown) return;
      final msg = widget.initialSuccessMessage;
      if (msg == null || msg.trim().isEmpty) return;
      _initialMessageShown = true;
      SnackBars.showSuccessSnackBar(context, msg.trim());
    });
  }

  @override
  void dispose() {
    _loginIdController.dispose();
    _pinController.dispose();
    _loginIdFocusNode.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _showOutletDialog(
    BuildContext context,
    LoginSuccessNeedsOutletSelection state,
  ) {
    if (_outletDialogShowing) return;
    _outletDialogShowing = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: context.read<LoginBloc>(),
          // BlocBuilder updates the loading spinner inside the dialog.
          // Navigation and full dismissal are handled by the outer BlocListener
          // via pushAndRemoveUntil, which clears the entire stack including the
          // dialog route — so we do NOT pop() from here.
          child: BlocBuilder<LoginBloc, LoginState>(
            builder: (ctx, s) {
              final isLoading = s is LoginOutletSelectionLoading;
              return OutletSelectionDialog(
                outlets: state.outlets,
                isLoading: isLoading,
                onOutletSelected: isLoading
                    ? (_) {}
                    : (outlet) {
                        ctx.read<LoginBloc>().add(OutletSelected(outlet));
                      },
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      _outletDialogShowing = false;
    });
  }

  bool _profileHasScannerRole(Profile profile) {
    return profile.roles.any((r) => r.toLowerCase().contains('scanner'));
  }

  void _navigateReplaceWithLogin(BuildContext ctx) {
    Navigator.of(ctx).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseMessagingService = Provider.of<FirebaseMessagingService>(
      context,
      listen: false,
    );

    final webSocketBloc = context.read<WebSocketBloc>();

    return BlocProvider(
      create: (context) => LoginBloc(
        firebaseMessagingService: firebaseMessagingService,
        webSocketBloc: webSocketBloc,
      ),
      child: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccessNeedsOutletSelection) {
            _showOutletDialog(context, state);
          } else if (state is LoginSuccess) {
            navigateToHomeForAuthenticatedProfile(context, state.profile);
          } else if (state is LoginSuccessClockInTooFar) {
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => LoginOutletTooFarPage(
                  profile: state.profile,
                  initialDetailMessage: state.message,
                  retryMode: LoginOutletTooFarRetryMode.driverClockIn,
                  driverOutlet: state.outlet,
                  verifyOutletId: null,
                  scannerMode: false,
                  operatorStyleMenus: false,
                  onLogoutPushLogin: _navigateReplaceWithLogin,
                ),
              ),
              (route) => false,
            );
          } else if (state is LoginSuccessLocationTooFar) {
            if (!context.mounted) return;
            final useScannerShell = _profileHasScannerRole(state.profile);
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => LoginOutletTooFarPage(
                  profile: state.profile,
                  initialDetailMessage: state.userFacingMessage,
                  retryMode: LoginOutletTooFarRetryMode.outletVerify,
                  verifyOutletId: state.outletId,
                  scannerMode: useScannerShell,
                  operatorStyleMenus: !useScannerShell,
                  onLogoutPushLogin: _navigateReplaceWithLogin,
                ),
              ),
              (route) => false,
            );
          } else if (state is LoginFailure) {
            // Dismiss outlet dialog so the error is visible (e.g. clock-in failed).
            final nav = Navigator.of(context);
            if (nav.canPop()) {
              nav.pop();
            }
            final t = context.read<AppTranslationsNotifier>();
            String displayMessage = state.message;
            if (state.message == TextConstants.validationPhoneRequired) {
              displayMessage = t.get(TextConstants.validationPhoneRequired);
            } else if (state.message ==
                TextConstants.validationPasswordRequired) {
              displayMessage = t.get(TextConstants.validationPasswordRequired);
            }
            SnackBars.showErrorSnackBar(context, displayMessage);
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: AppColors.primarySurface,
            appBar: const CustomAppBar(hideParkedCarsAction: true),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: LoginForm(
                        loginIdController: _loginIdController,
                        pinController: _pinController,
                        loginIdFocusNode: _loginIdFocusNode,
                        pinFocusNode: _pinFocusNode,
                      ),
                    ),
                  ),
                  const Footer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
