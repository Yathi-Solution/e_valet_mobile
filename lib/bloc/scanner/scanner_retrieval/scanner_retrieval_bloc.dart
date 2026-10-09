import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:niloufer_valet_mobile/api/operator/operator_dashboard/operator_retrieval_requests_api_service.dart';
import 'package:niloufer_valet_mobile/bloc/scanner/scanner_retrieval/scanner_retrieval_event.dart';
import 'package:niloufer_valet_mobile/bloc/scanner/scanner_retrieval/scanner_retrieval_state.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/bloc/websocket/websocket_bloc.dart';

class ScannerRetrievalBloc
    extends Bloc<ScannerRetrievalEvent, ScannerRetrievalState> {
  final WebSocketBloc? webSocketBloc;
  StreamSubscription<dynamic>? _sessionStatusSubscription;
  StreamSubscription<bool>? _webSocketConnectionSubscription;

  ScannerRetrievalBloc({this.webSocketBloc})
      : super(const ScannerRetrievalInitial()) {
    on<ScannerRetrievalFetchRequested>(_onFetchRequested);
    on<ScannerRetrievalRefreshSilently>(_onRefreshSilently);

    _setupWebSocketConnectionMonitoring();
  }

  /// Monitor WebSocket connection and setup/re-setup listeners when connected.
  void _setupWebSocketConnectionMonitoring() {
    if (webSocketBloc == null) {
      return;
    }

    _webSocketConnectionSubscription =
        webSocketBloc!.service.connectionStream.listen((isConnected) {
      if (isConnected) {
        _setupWebSocketListeners();
      } else {
        _cleanupWebSocketListeners();
      }
    });

    if (webSocketBloc!.isConnected) {
      _setupWebSocketListeners();
    }
  }

  void _cleanupWebSocketListeners() {
    _sessionStatusSubscription?.cancel();
    _sessionStatusSubscription = null;
  }

  /// Setup WebSocket listener for session:status_changed (same as operator dashboard).
  void _setupWebSocketListeners() {
    if (webSocketBloc == null) return;

    _cleanupWebSocketListeners();

    try {
      final sessionStatusStream =
          webSocketBloc!.service.getEventStream('session:status_changed');

      _sessionStatusSubscription = sessionStatusStream.listen(
        (data) {
          add(const ScannerRetrievalRefreshSilently());
        },
        onError: (error) {
          print(
              'ScannerRetrievalBloc: Error listening to session status: $error');
        },
      );
    } catch (e) {
      print('ScannerRetrievalBloc: Error setting up WebSocket listeners: $e');
    }
  }

  Future<void> _onFetchRequested(
    ScannerRetrievalFetchRequested event,
    Emitter<ScannerRetrievalState> emit,
  ) async {
    emit(const ScannerRetrievalLoading());
    final outletId = dotenv.env['OUTLET_ID'] ?? '1';

    try {
      final response =
          await OperatorRetrievalRequestsApiService.getRetrievalRequests(
        outletId: outletId,
      );
      emit(ScannerRetrievalLoaded(response));
    } on ApiException catch (e) {
      emit(ScannerRetrievalError(e.message));
    } catch (e) {
      emit(ScannerRetrievalError(
        getDisplayErrorMessage(e),
      ));
    }
  }

  /// Silent refresh (no loading state). Used when WebSocket emits session:status_changed.
  Future<void> _onRefreshSilently(
    ScannerRetrievalRefreshSilently event,
    Emitter<ScannerRetrievalState> emit,
  ) async {
    final outletId = dotenv.env['OUTLET_ID'] ?? '1';

    try {
      final response =
          await OperatorRetrievalRequestsApiService.getRetrievalRequests(
        outletId: outletId,
      );
      emit(ScannerRetrievalLoaded(response));
    } catch (e) {
      // Keep current state on silent refresh failure
      print('ScannerRetrievalBloc: Silent refresh failed: $e');
    }
  }

  @override
  Future<void> close() {
    _cleanupWebSocketListeners();
    _webSocketConnectionSubscription?.cancel();
    _webSocketConnectionSubscription = null;
    return super.close();
  }
}
