import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:niloufer_valet_mobile/api/operator/operator_cards/card_assignments_api_service.dart';
import 'package:niloufer_valet_mobile/api/operator/operator_valet/valet_list_api_service.dart';
import 'package:niloufer_valet_mobile/bloc/operator/operator_cards/operator_cards_event.dart';
import 'package:niloufer_valet_mobile/bloc/operator/operator_cards/operator_cards_state.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_cards/card_assignments_response.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_valet/valet_response.dart';

class OperatorCardsBloc extends Bloc<OperatorCardsEvent, OperatorCardsState> {
  OperatorCardsBloc({required this.outletId})
      : super(const OperatorCardsInitial()) {
    on<OperatorCardsLoadRequested>(_onLoadRequested);
    on<OperatorCardsRefreshRequested>(_onRefreshRequested);
    on<OperatorCardsSearchQueryChanged>(_onSearchQueryChanged);
  }

  final String outletId;

  Future<void> _onLoadRequested(
    OperatorCardsLoadRequested event,
    Emitter<OperatorCardsState> emit,
  ) async {
    emit(const OperatorCardsLoading());
    await _fetchData(
      emit,
      preserveSearchQuery: '',
      preserveDataRevision: 0,
    );
  }

  Future<void> _onRefreshRequested(
    OperatorCardsRefreshRequested event,
    Emitter<OperatorCardsState> emit,
  ) async {
    final current = state;
    var searchQuery = '';
    var revision = 0;
    if (current is OperatorCardsReady) {
      searchQuery = current.searchQuery;
      revision = current.dataRevision;
      emit(current.copyWith(isRefreshing: true));
    } else {
      emit(const OperatorCardsLoading());
    }
    await _fetchData(
      emit,
      preserveSearchQuery: searchQuery,
      preserveDataRevision: revision,
    );
  }

  void _onSearchQueryChanged(
    OperatorCardsSearchQueryChanged event,
    Emitter<OperatorCardsState> emit,
  ) {
    final current = state;
    if (current is OperatorCardsReady) {
      emit(current.copyWith(searchQuery: event.query));
    }
  }

  Future<void> _fetchData(
    Emitter<OperatorCardsState> emit, {
    required String preserveSearchQuery,
    required int preserveDataRevision,
  }) async {
    try {
      final valetsResponse =
          await ValetListApiService.getValets(outletId: outletId);
      final assignmentsResponse =
          await CardAssignmentsApiService.getCardAssignments(
              outletId: outletId);

      final list = List<ValetResponse>.from(valetsResponse.valets)
        ..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

      final byDriver =
          cardNumbersByDriverFromAssignments(assignmentsResponse.assignments);

      emit(OperatorCardsReady(
        valets: list,
        cardNumbersByDriverId: byDriver,
        searchQuery: preserveSearchQuery,
        isRefreshing: false,
        dataRevision: preserveDataRevision + 1,
      ));
    } catch (e) {
      emit(OperatorCardsLoadFailure(message: getDisplayErrorMessage(e)));
    }
  }
}
