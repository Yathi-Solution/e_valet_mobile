import 'package:equatable/equatable.dart';
import 'package:niloufer_valet_mobile/models/oauth/client_summary.dart';
import 'package:niloufer_valet_mobile/models/oauth/profile.dart';
import 'package:niloufer_valet_mobile/models/outlet/outlet.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

/// Login API succeeded; now waiting for the user to select an outlet.
/// Emitted for ALL roles (driver, operator, scanner).
class LoginSuccessNeedsOutletSelection extends LoginState {
  final Profile profile;
  final List<Outlet> outlets;
  final bool isDriver;
  final bool isOperator;
  final bool isScanner;

  const LoginSuccessNeedsOutletSelection({
    required this.profile,
    required this.outlets,
    required this.isDriver,
    required this.isOperator,
    required this.isScanner,
  });

  @override
  List<Object?> get props =>
      [profile, outlets, isDriver, isOperator, isScanner];
}

/// Login returned a Platform token; the user must pick a Client to enter.
class LoginNeedsClientSelection extends LoginState {
  final List<ClientSummary> clients;

  const LoginNeedsClientSelection(this.clients);

  @override
  List<Object?> get props => [clients];
}

/// Outlet selected; now performing clock-in / verify-location in the background.
class LoginOutletSelectionLoading extends LoginState {
  const LoginOutletSelectionLoading();
}

class LoginSuccess extends LoginState {
  final Profile profile;

  const LoginSuccess(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Driver logged in but clock-in failed because they are too far from the outlet.
class LoginSuccessClockInTooFar extends LoginState {
  final Profile profile;
  final String message;

  /// Outlet chosen in the dialog — not yet persisted when clock-in fails for distance.
  final Outlet outlet;

  const LoginSuccessClockInTooFar({
    required this.profile,
    required this.message,
    required this.outlet,
  });

  @override
  List<Object?> get props => [profile, message, outlet];
}

/// Operator/Scanner logged in but verify-location returned withinBounds: false.
class LoginSuccessLocationTooFar extends LoginState {
  final Profile profile;

  /// Persisted before verify-location (operator / scanner admin path); used for Retry.
  final int outletId;

  final String outletName;
  final double distanceMeters;
  final double allowedRadiusMeters;

  /// When the API returns HTTP error with a "too far" message (no JSON body).
  final String? detailMessage;

  const LoginSuccessLocationTooFar({
    required this.profile,
    required this.outletId,
    required this.outletName,
    required this.distanceMeters,
    required this.allowedRadiusMeters,
    this.detailMessage,
  });

  @override
  List<Object?> get props => [
        profile,
        outletId,
        outletName,
        distanceMeters,
        allowedRadiusMeters,
        detailMessage,
      ];

  /// Text for [ClockInTooFarScreen]: API detail line if present, else distance/outlet summary.
  String get userFacingMessage {
    final trimmed = detailMessage?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;

    final buf = StringBuffer();
    if (outletName.isNotEmpty) {
      buf.write('Outlet: $outletName');
    }
    if (distanceMeters > 0 || allowedRadiusMeters > 0) {
      if (buf.isNotEmpty) buf.write('\n\n');
      String fmt(double m) => m >= 1000
          ? '${(m / 1000).toStringAsFixed(1)} km'
          : '${m.toStringAsFixed(0)} m';
      buf.write('Your distance: ${fmt(distanceMeters)}\n');
      buf.write('Allowed radius: ${fmt(allowedRadiusMeters)}');
    }
    final s = buf.toString();
    if (s.isEmpty) {
      return 'You are outside the allowed area for this outlet.';
    }
    return s;
  }
}

class LoginFailure extends LoginState {
  final String message;

  const LoginFailure(this.message);

  @override
  List<Object?> get props => [message];
}
