import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:niloufer_valet_mobile/api/operator/operator_dashboard/operator_dashboard_api_service.dart';
import 'package:niloufer_valet_mobile/api/operator/operator_dashboard/operator_available_drivers_api_service.dart';
import 'package:niloufer_valet_mobile/api/operator/operator_dashboard/operator_retrieval_requests_api_service.dart';
import 'package:niloufer_valet_mobile/api/operator/parked_car/operator_digital_key_rack_api_service.dart';
import 'package:niloufer_valet_mobile/api/operator/operator_dashboard/operator_assign_retrieval_api_service.dart';
import 'package:niloufer_valet_mobile/api/operator/operator_dashboard/operator_cancel_assignment_api_service.dart';
import 'package:niloufer_valet_mobile/api/operator/operator_dashboard/operator_manual_retrieval_api_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/assigned_to.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/assign_retrieval_request.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/manual_retrieval_request.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/retrieval_requests_response.dart';
import 'package:niloufer_valet_mobile/bloc/websocket/websocket_bloc.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/operator_available_drivers_response.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/operator_dashboard_kpis_response.dart';
import 'operator_dashboard_event.dart';
import 'operator_dashboard_state.dart';

class OperatorDashboardBloc
    extends Bloc<OperatorDashboardEvent, OperatorDashboardState> {
  final WebSocketBloc? webSocketBloc;
  final String outletId;
  StreamSubscription<dynamic>? _sessionStatusSubscription;
  StreamSubscription<dynamic>? _statsUpdateSubscription;
  StreamSubscription<dynamic>? _driverStatusChangedSubscription;
  StreamSubscription<dynamic>? _newParkingSubscription;
  StreamSubscription<bool>? _webSocketConnectionSubscription;

  OperatorDashboardBloc({
    this.webSocketBloc,
    required this.outletId,
  }) : super(const OperatorDashboardInitial()) {
    on<FetchDashboardKpis>(_onFetchDashboardKpis);
    on<RefreshDashboardKpisSilently>(_onRefreshDashboardKpisSilently);
    on<AssignDriverToRetrieval>(_onAssignDriverToRetrieval);
    on<CancelRetrievalAssignment>(_onCancelRetrievalAssignment);
    on<CreateManualRetrievalRequest>(_onCreateManualRetrievalRequest);
    on<NewParkingEvent>(_onNewParkingEvent);

    // Monitor WebSocket connection and re-setup listeners on (re)connect
    _setupWebSocketConnectionMonitoring();
  }

  /// Monitor WebSocket connection and setup/re-setup listeners when connected.
  /// This ensures event subscriptions are re-established after disconnect/reconnect
  /// (e.g. after idle timeout), so real-time updates keep working.
  void _setupWebSocketConnectionMonitoring() {
    if (webSocketBloc == null) {
      print(
        'WebSocketBloc not provided to OperatorDashboardBloc. '
        'Real-time updates will be disabled.',
      );
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
    _statsUpdateSubscription?.cancel();
    _statsUpdateSubscription = null;
    _driverStatusChangedSubscription?.cancel();
    _driverStatusChangedSubscription = null;
    _newParkingSubscription?.cancel();
    _newParkingSubscription = null;
  }

  /// Setup WebSocket listeners for real-time updates.
  /// Called on (re)connect; cleanup is done first to avoid duplicate subscriptions.
  void _setupWebSocketListeners() {
    if (webSocketBloc == null) return;

    _cleanupWebSocketListeners();

    try {
      // Listen to session:status_changed event
      final sessionStatusStream =
          webSocketBloc!.service.getEventStream('session:status_changed');

      _sessionStatusSubscription = sessionStatusStream.listen(
        (data) {
          // Silently refresh KPIs and retrieval requests when session status changes
          add(
            RefreshDashboardKpisSilently(
              outletId: outletId,
              refreshKpis: true,
              refreshDrivers: true,
              refreshRequests: true,
            ),
          );
        },
        onError: (error) {
          print('Error listening to session status updates: $error');
        },
      );

      // Listen to outlet:stats_updated event
      final statsStream =
          webSocketBloc!.service.getEventStream('outlet:stats_updated');

      _statsUpdateSubscription = statsStream.listen(
        (data) {
          // Silently refresh only KPIs when stats update is received
          add(
            RefreshDashboardKpisSilently(
              outletId: outletId,
              refreshKpis: true,
              refreshDrivers: false,
              refreshRequests: false, // Stats updates only affect KPIs
            ),
          );
        },
        onError: (error) {
          print('Error listening to stats updates: $error');
        },
      );

      // Listen to driver:status_changed event
      final driverStatusChangedStream =
          webSocketBloc!.service.getEventStream('driver:status_changed');

      _driverStatusChangedSubscription = driverStatusChangedStream.listen(
        (data) {
          // Silently refresh only available drivers when driver status changes
          add(
            RefreshDashboardKpisSilently(
              outletId: outletId,
              refreshKpis: true,
              refreshDrivers: true,
              refreshRequests: false,
            ),
          );
        },
        onError: (error) {
          print('Error listening to driver status updates: $error');
        },
      );

      // Listen to session:new_parking event
      final newParkingStream =
          webSocketBloc!.service.getEventStream('session:new_parking');

      _newParkingSubscription = newParkingStream.listen(
        (data) {
          add(
            RefreshDashboardKpisSilently(
              outletId: outletId,
              refreshKpis: true,
              refreshDrivers: true,
              refreshRequests: false,
            ),
          );
        },
        onError: (error) {
          print('Error listening to new parking updates: $error');
        },
      );
    } catch (e) {
      print('Error setting up WebSocket listeners: $e');
    }
  }

  Future<void> _onFetchDashboardKpis(
    FetchDashboardKpis event,
    Emitter<OperatorDashboardState> emit,
  ) async {
    emit(const OperatorDashboardLoading());
    try {
      // Fetch KPIs, available drivers, retrieval requests, and digital key rack in parallel
      final results = await Future.wait([
        OperatorDashboardApiService.getDashboardKpis(
          outletId: event.outletId,
        ),
        OperatorAvailableDriversApiService.getAvailableDrivers(
          outletId: event.outletId,
        ),
        OperatorRetrievalRequestsApiService.getRetrievalRequests(
          outletId: event.outletId,
        ),
        OperatorDigitalKeyRackApiService.getDigitalKeyRack(
          outletId: event.outletId,
        ),
      ]);

      final kpis = results[0] as dynamic;
      final availableDrivers = results[1] as dynamic;
      final retrievalRequests = results[2] as dynamic;
      final digitalKeyRack = results[3] as dynamic;

      emit(OperatorDashboardLoaded(
        kpis: kpis,
        availableDrivers: availableDrivers,
        retrievalRequests: retrievalRequests,
        digitalKeyRack: digitalKeyRack,
      ));
    } catch (e) {
      emit(OperatorDashboardError(getDisplayErrorMessage(e)));
    }
  }

  /// Refresh KPIs, available drivers, and retrieval requests silently without showing loading state
  /// Used for real-time WebSocket updates
  Future<void> _onRefreshDashboardKpisSilently(
    RefreshDashboardKpisSilently event,
    Emitter<OperatorDashboardState> emit,
  ) async {
    // Only refresh if we're already in a loaded state
    if (state is! OperatorDashboardLoaded) {
      return;
    }

    final currentState = state as OperatorDashboardLoaded;

    try {
      // Build list of futures based on what needs to be refreshed
      final futures = <Future<dynamic>>[];

      if (event.refreshKpis) {
        futures.add(OperatorDashboardApiService.getDashboardKpis(
          outletId: event.outletId,
        ));
      }

      if (event.refreshDrivers) {
        futures.add(OperatorAvailableDriversApiService.getAvailableDrivers(
          outletId: event.outletId,
        ));
      }

      if (event.refreshRequests) {
        futures.add(OperatorRetrievalRequestsApiService.getRetrievalRequests(
          outletId: event.outletId,
        ));
      }

      // If nothing to refresh, return early
      if (futures.isEmpty) {
        return;
      }

      // Fetch selected data in parallel
      final results = await Future.wait(futures);

      // Extract results based on order
      int resultIndex = 0;
      final kpis =
          event.refreshKpis ? results[resultIndex++] : currentState.kpis;
      final availableDrivers = event.refreshDrivers
          ? results[resultIndex++]
          : currentState.availableDrivers;
      final retrievalRequests = event.refreshRequests
          ? results[resultIndex++]
          : currentState.retrievalRequests;

      // Emit updated state with new data
      emit(OperatorDashboardLoaded(
        kpis: kpis,
        availableDrivers: availableDrivers,
        retrievalRequests: retrievalRequests,
        digitalKeyRack: currentState.digitalKeyRack,
      ));
    } catch (e) {
      // Silently fail - don't show error for background updates
      // Just keep the current state
      print('Silent dashboard refresh failed: $e');
    }
  }

  Future<void> _onAssignDriverToRetrieval(
    AssignDriverToRetrieval event,
    Emitter<OperatorDashboardState> emit,
  ) async {
    final previousLoaded = state is OperatorDashboardLoaded
        ? state as OperatorDashboardLoaded
        : null;

    emit(const AssignmentInProgress());

    try {
      final apiService = OperatorAssignRetrievalApiService();
      final response = await apiService.assignRetrieval(
        request: AssignRetrievalRequest(
          driverUserId: event.driverUserId,
          sessionId: event.sessionId,
        ),
      );

      emit(AssignmentSuccess(response));
      // Restore loaded state so the UI does not show a blank screen; refresh will update data.
      if (previousLoaded != null) {
        emit(previousLoaded);
      }
    } catch (e) {
      emit(AssignmentError(getDisplayErrorMessage(e)));
      if (previousLoaded != null) {
        emit(previousLoaded);
      }
    }
  }

  Future<void> _onCancelRetrievalAssignment(
    CancelRetrievalAssignment event,
    Emitter<OperatorDashboardState> emit,
  ) async {
    final previousLoaded = state is OperatorDashboardLoaded
        ? state as OperatorDashboardLoaded
        : null;

    emit(const CancelAssignmentInProgress());

    try {
      final apiService = OperatorCancelAssignmentApiService();
      final response = await apiService.cancelAssignment(
        sessionId: event.sessionId,
      );

      emit(CancelAssignmentSuccess(response));
      if (previousLoaded != null) {
        final updatedRequests = previousLoaded.retrievalRequests.requests
            .map((r) => r.sessionId == response.sessionId
                ? r.copyWith(
                    status: response.status,
                    assignedTo: AssignedTo(
                      userId: '',
                      name: '',
                      phone: '',
                    ),
                  )
                : r)
            .toList();
        emit(previousLoaded.copyWith(
          retrievalRequests: RetrievalRequestsResponse(
            requests: updatedRequests,
          ),
        ));
      }
      // Delay the background refresh so the UI can process the optimistic
      // state first, avoiding a race where the refresh overwrites it and
      // causes flicker (session briefly showing as assigned again).
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!isClosed) {
          add(RefreshDashboardKpisSilently(
            outletId: outletId,
            refreshKpis: true,
            refreshDrivers: true,
            refreshRequests: true,
          ));
        }
      });
    } catch (e) {
      emit(CancelAssignmentError(
        sessionId: event.sessionId,
        message: e.toString(),
      ));
      if (previousLoaded != null) {
        emit(previousLoaded);
      }
    }
  }

  Future<void> _onCreateManualRetrievalRequest(
    CreateManualRetrievalRequest event,
    Emitter<OperatorDashboardState> emit,
  ) async {
    // Store the current loaded state to restore after request
    final previousState = state is OperatorDashboardLoaded
        ? state as OperatorDashboardLoaded
        : null;

    emit(const ManualRequestInProgress());

    try {
      final apiService = OperatorManualRetrievalApiService();
      final response = await apiService.createManualRetrievalRequest(
        outletId: event.outletId,
        request: ManualRetrievalRequest(
          cardNumber: event.cardNumber,
        ),
      );

      emit(ManualRequestSuccess(response.message));

      // Restore the previous dashboard state immediately so UI doesn't go blank
      if (previousState != null) {
        emit(previousState);
      }

      // Explicitly trigger a silent refresh for retrieval requests only
      // This ensures immediate update without waiting for websocket
      add(RefreshDashboardKpisSilently(
        outletId: event.outletId,
        refreshKpis: false,
        refreshDrivers: false,
        refreshRequests: true,
      ));
    } catch (e) {
      // Show a business-friendly error message for card not found
      String errorMessage = e is ApiException ? e.displayMessage : getDisplayErrorMessage(e);
      final cardNotFoundRegExp =
          RegExp(r'Card #[0-9]+ not found in outlet [0-9]+');
      final match = cardNotFoundRegExp.firstMatch(errorMessage);
      if (match != null) {
        errorMessage =
            'No parked vehicle found for this card number. Please enter a valid card number.';
      }
      emit(ManualRequestError(errorMessage));

      // Restore the previous dashboard state after error too
      if (previousState != null) {
        emit(previousState);
      }
    }
  }

  Future<void> _onNewParkingEvent(
    NewParkingEvent event,
    Emitter<OperatorDashboardState> emit,
  ) async {
    if (state is! OperatorDashboardLoaded) {
      return;
    }

    final currentState = state as OperatorDashboardLoaded;

    try {
      final results = await Future.wait([
        OperatorDashboardApiService.getDashboardKpis(
          outletId: event.outletId,
        ),
        OperatorAvailableDriversApiService.getAvailableDrivers(
          outletId: event.outletId,
        ),
      ]);

      final kpis =
          results[0] as OperatorDashboardKpisResponse; // cast to correct type
      final availableDrivers = results[1]
          as OperatorAvailableDriversResponse; // cast to correct type

      emit(
        OperatorDashboardLoaded(
          kpis: kpis,
          availableDrivers: availableDrivers,
          retrievalRequests: currentState.retrievalRequests,
          digitalKeyRack: currentState.digitalKeyRack,
        ),
      );
    } catch (e) {
      developer.log(
        'New parking refresh (kpis + drivers) failed: $e',
        name: 'OperatorDashboardBloc',
      );
    }
  }

  @override
  Future<void> close() async {
    _webSocketConnectionSubscription?.cancel();
    await _sessionStatusSubscription?.cancel();
    await _statsUpdateSubscription?.cancel();
    await _driverStatusChangedSubscription?.cancel();
    await _newParkingSubscription?.cancel();
    return super.close();
  }
}
