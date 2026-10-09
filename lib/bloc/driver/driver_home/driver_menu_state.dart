import 'package:equatable/equatable.dart';
import 'package:niloufer_valet_mobile/models/driver/pre_break/pre_break_info_response.dart';
import 'package:niloufer_valet_mobile/models/driver/parked/my_parked_sessions_response.dart';
import 'package:niloufer_valet_mobile/models/driver/session/pending_sessions_response.dart';
import 'package:niloufer_valet_mobile/models/oauth/logout_response.dart';

abstract class DriverMenuState extends Equatable {
  const DriverMenuState();

  @override
  List<Object?> get props => [];
}

class DriverMenuInitial extends DriverMenuState {
  const DriverMenuInitial();
}

enum DriverMenuActionType { logout, profile, guidelines, help }

class DriverMenuAction extends DriverMenuState {
  final DriverMenuActionType action;

  const DriverMenuAction(this.action);

  @override
  List<Object?> get props => [action];
}

class DriverMenuLogoutLoading extends DriverMenuState {
  const DriverMenuLogoutLoading();
}

class DriverMenuLogoutPrecheckLoading extends DriverMenuState {
  const DriverMenuLogoutPrecheckLoading();
}

class DriverMenuLogoutSuccess extends DriverMenuState {
  final LogoutResponse response;

  const DriverMenuLogoutSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class DriverMenuLogoutFailure extends DriverMenuState {
  final String message;

  const DriverMenuLogoutFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class DriverMenuLogoutBlockedByPendingWork extends DriverMenuState {
  final PreBreakInfoResponse preBreakInfo;

  const DriverMenuLogoutBlockedByPendingWork(this.preBreakInfo);

  @override
  List<Object?> get props => [preBreakInfo];
}

class DriverHomeLoaded extends DriverMenuState {
  final String driverName;
  final bool isOnBreak;
  final bool isOnline;
  final PendingSessionsResponse? pendingSessions;
  final int parkedCarsCount;
  final MyParkedSessionsResponse? parkedCarsData;

  const DriverHomeLoaded({
    required this.driverName,
    required this.isOnBreak,
    required this.isOnline,
    this.pendingSessions,
    this.parkedCarsCount = 0,
    this.parkedCarsData,
  });

  DriverHomeLoaded copyWith({
    String? driverName,
    bool? isOnBreak,
    bool? isOnline,
    PendingSessionsResponse? pendingSessions,
    int? parkedCarsCount,
    MyParkedSessionsResponse? parkedCarsData,
  }) {
    return DriverHomeLoaded(
      driverName: driverName ?? this.driverName,
      isOnBreak: isOnBreak ?? this.isOnBreak,
      isOnline: isOnline ?? this.isOnline,
      pendingSessions: pendingSessions ?? this.pendingSessions,
      parkedCarsCount: parkedCarsCount ?? this.parkedCarsCount,
      parkedCarsData: parkedCarsData ?? this.parkedCarsData,
    );
  }

  @override
  List<Object?> get props => [
        driverName,
        isOnBreak,
        isOnline,
        pendingSessions,
        parkedCarsCount,
        parkedCarsData,
      ];
}
