import 'package:equatable/equatable.dart';
import 'package:evalet/models/operator/operator_dashboard/retrieval_requests_response.dart';

abstract class ScannerRetrievalState extends Equatable {
  const ScannerRetrievalState();

  @override
  List<Object?> get props => [];
}

class ScannerRetrievalInitial extends ScannerRetrievalState {
  const ScannerRetrievalInitial();
}

class ScannerRetrievalLoading extends ScannerRetrievalState {
  const ScannerRetrievalLoading();
}

class ScannerRetrievalLoaded extends ScannerRetrievalState {
  final RetrievalRequestsResponse response;

  const ScannerRetrievalLoaded(this.response);

  @override
  List<Object?> get props => [response];
}

class ScannerRetrievalError extends ScannerRetrievalState {
  final String message;

  const ScannerRetrievalError(this.message);

  @override
  List<Object?> get props => [message];
}
