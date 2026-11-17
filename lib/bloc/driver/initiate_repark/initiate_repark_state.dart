import 'package:equatable/equatable.dart';
import 'package:evalet/models/driver/re-park/initiate_repark_response.dart';

abstract class InitiateReparkState extends Equatable {
  const InitiateReparkState();

  @override
  List<Object?> get props => [];
}

class InitiateReparkInitial extends InitiateReparkState {
  const InitiateReparkInitial();
}

class InitiateReparkLoading extends InitiateReparkState {
  const InitiateReparkLoading();
}

class InitiateReparkSuccess extends InitiateReparkState {
  final InitiateReparkResponse response;

  const InitiateReparkSuccess({required this.response});

  @override
  List<Object?> get props => [response];
}

class InitiateReparkError extends InitiateReparkState {
  final String message;

  const InitiateReparkError({required this.message});

  @override
  List<Object?> get props => [message];
}
