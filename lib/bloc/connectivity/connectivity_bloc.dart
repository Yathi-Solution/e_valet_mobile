import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'connectivity_event.dart';
import 'connectivity_state.dart';
import 'package:niloufer_valet_mobile/services/offline_sync/offline_parking_service.dart';
import 'package:niloufer_valet_mobile/services/connectivity/driver_connectivity_log_service.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _connectivityFlushTimer;

  ConnectivityBloc() : super(ConnectivityInitial()) {
    on<CheckConnectivity>(_onCheckConnectivity);
    on<ConnectivityChanged>(_onConnectivityChanged);

    // Initial check
    add(CheckConnectivity());

    // Listen for changes
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
      add(ConnectivityChanged(results));
    });

    _connectivityFlushTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(DriverConnectivityLogService.instance.tryFlushIfDue());
    });
  }

  Future<void> _onCheckConnectivity(
    CheckConnectivity event,
    Emitter<ConnectivityState> emit,
  ) async {
    final results = await _connectivity.checkConnectivity();
    await _applyConnectivityResults(results, emit);
  }

  Future<void> _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<ConnectivityState> emit,
  ) async {
    await _applyConnectivityResults(event.results, emit);
  }

  /// No carrier / Wi‑Fi, or link is up but DNS cannot resolve (matches "Failed host lookup" cases).
  Future<void> _applyConnectivityResults(
    List<ConnectivityResult> results,
    Emitter<ConnectivityState> emit,
  ) async {
    final noInterface =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);

    if (noInterface) {
      unawaited(
        DriverConnectivityLogService.instance.handleInternetState(
          isOnline: false,
          results: results,
        ),
      );
      emit(ConnectivityUnavailable());
      return;
    }

    final reachable = await _dnsReachable();
    unawaited(
      DriverConnectivityLogService.instance.handleInternetState(
        isOnline: reachable,
        results: results,
      ),
    );

    if (reachable) {
      OfflineParkingService.syncPendingData();
      emit(ConnectivityOnline());
      unawaited(DriverConnectivityLogService.instance.tryFlushIfDue());
    } else {
      emit(ConnectivityUnavailable());
    }
  }

  Future<bool> _dnsReachable() async {
    try {
      await InternetAddress.lookup('cloudflare.com').timeout(
        const Duration(seconds: 4),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> close() {
    _connectivityFlushTimer?.cancel();
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
