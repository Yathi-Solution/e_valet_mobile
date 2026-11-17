import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:evalet/api/operator/operator_valet/valet_list_api_service.dart';
import 'package:evalet/bloc/operator/operator_valet/operator_valets/valet_list_event.dart';
import 'package:evalet/bloc/operator/operator_valet/operator_valets/valet_list_state.dart';
import 'package:evalet/models/core/api_exceptions.dart';

class ValetListBloc extends Bloc<ValetListEvent, ValetListState> {
  ValetListBloc() : super(ValetListInitial()) {
    on<FetchValetList>(_onFetchValetList);
  }

  Future<void> _onFetchValetList(
    FetchValetList event,
    Emitter<ValetListState> emit,
  ) async {
    emit(ValetListLoading());
    try {
      final response =
          await ValetListApiService.getValets(outletId: event.outletId);
      emit(ValetListLoaded(response: response));
    } catch (e) {
      emit(ValetListError(message: getDisplayErrorMessage(e)));
    }
  }
}
