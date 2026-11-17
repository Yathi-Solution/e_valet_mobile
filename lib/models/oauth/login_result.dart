import 'package:evalet/models/oauth/client_summary.dart';
import 'package:evalet/models/oauth/profile.dart';

/// Outcome of POST /auth/login: either a Client-bound session (ready to use)
/// or a Platform token that still needs a Client chosen.
class LoginResult {
  final Profile? profile;
  final List<ClientSummary> clients;

  const LoginResult.ready(Profile this.profile) : clients = const [];
  const LoginResult.needsClient(this.clients) : profile = null;

  bool get needsClientSelection => profile == null;
}
