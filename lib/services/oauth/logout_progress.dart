import 'package:flutter/foundation.dart';

/// App-wide "logout is running" flag.
///
/// Logout can be started from any screen (app-bar overflow menu, operator
/// drawer), so the loader cannot live in one screen's widget tree: a screen
/// pushed on top would hide it. The menu blocs raise this flag for the whole
/// logout and `LogoutProgressOverlay` (mounted above the navigator) shows the
/// blocking loader while it is set.
class LogoutProgress {
  LogoutProgress._();

  static final ValueNotifier<bool> active = ValueNotifier<bool>(false);
}
