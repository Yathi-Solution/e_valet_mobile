/// Hook for the app shell to react when the server ends the session
/// (401 SESSION_ENDED). Local tokens are already cleared when this fires.
class SessionEvents {
  SessionEvents._();

  static void Function(String message)? onSessionEnded;

  static bool _ending = false;

  /// Clears local auth state and notifies the app once per burst of 401s.
  static Future<void> end(
    Future<void> Function() clearLocal,
    String message,
  ) async {
    if (_ending) return;
    _ending = true;
    try {
      await clearLocal();
      onSessionEnded?.call(message);
    } finally {
      Future.delayed(const Duration(seconds: 2), () => _ending = false);
    }
  }
}
