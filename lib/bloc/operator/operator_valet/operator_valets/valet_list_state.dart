import 'package:equatable/equatable.dart';
import 'package:evalet/models/operator/operator_valet/valet_list_response.dart';

abstract class ValetListState extends Equatable {
  const ValetListState();

  @override
  List<Object?> get props => [];
}

class ValetListInitial extends ValetListState {}

class ValetListLoading extends ValetListState {}

class ValetListLoaded extends ValetListState {
  final ValetListResponse response;

  const ValetListLoaded({required this.response});

  @override
  List<Object?> get props => [response];
}

class ValetListError extends ValetListState {
  final String message;

  const ValetListError({required this.message});

  @override
  List<Object?> get props => [message];
}
