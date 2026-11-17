import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:evalet/bloc/oauth/login/login_bloc.dart';
import 'package:evalet/bloc/oauth/login/login_event.dart';
import 'package:evalet/bloc/oauth/login/login_state.dart';
import 'package:evalet/models/oauth/client_summary.dart';
import 'package:evalet/ui/common/widgets/client_selection_dialog.dart';
import 'package:evalet/ui/common/widgets/outlet_selection_dialog.dart';

/// The one dialog for the post-password login steps: pick a client (when the
/// account has several), then pick an outlet.
///
/// It stays open across both steps and swaps its content from the bloc state,
/// so the user goes client -> outlet without dropping back to the login form
/// in between. It never pops itself after a selection: the login screen's
/// listener either replaces the whole stack (success) or pops it (failure).
///
/// Must be built under a [BlocProvider] of [LoginBloc].
class LoginSelectionDialog extends StatefulWidget {
  const LoginSelectionDialog({super.key});

  @override
  State<LoginSelectionDialog> createState() => _LoginSelectionDialogState();
}

class _LoginSelectionDialogState extends State<LoginSelectionDialog> {
  // The loading states carry no data, so keep the last lists to render under
  // the spinner.
  List<ClientSummary> _clients = const [];
  LoginSuccessNeedsOutletSelection? _outletStep;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        if (state is LoginNeedsClientSelection) {
          _clients = state.clients;
          _outletStep = null;
        } else if (state is LoginSuccessNeedsOutletSelection) {
          _outletStep = state;
        }

        final bloc = context.read<LoginBloc>();
        final outletStep = _outletStep;
        final Widget dialog;

        if (outletStep != null) {
          final isLoading = state is LoginOutletSelectionLoading;
          dialog = OutletSelectionDialog(
            key: const ValueKey('outlet-step'),
            outlets: outletStep.outlets,
            roles: outletStep.profile.roles,
            isLoading: isLoading,
            onOutletSelected: isLoading
                ? (_) {}
                : (outlet) => bloc.add(OutletSelected(outlet)),
          );
        } else {
          // LoginLoading here means a client was picked and its profile and
          // outlets are being fetched.
          dialog = ClientSelectionDialog(
            key: const ValueKey('client-step'),
            clients: _clients,
            isLoading: state is LoginLoading,
            onClientSelected: (client) => bloc.add(ClientSelected(client.id)),
            onCancel: () => Navigator.of(context).pop(),
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: dialog,
        );
      },
    );
  }
}
