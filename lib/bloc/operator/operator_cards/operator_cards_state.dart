import 'package:equatable/equatable.dart';
import 'package:evalet/models/operator/operator_valet/valet_response.dart';

abstract class OperatorCardsState extends Equatable {
  const OperatorCardsState();

  @override
  List<Object?> get props => [];
}

class OperatorCardsInitial extends OperatorCardsState {
  const OperatorCardsInitial();
}

class OperatorCardsLoading extends OperatorCardsState {
  const OperatorCardsLoading();
}

class OperatorCardsLoadFailure extends OperatorCardsState {
  final String message;

  const OperatorCardsLoadFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class OperatorCardsReady extends OperatorCardsState {
  final List<ValetResponse> valets;

  /// Card numbers per driver from GET /operators/card-assignments (driverUserId → numbers).
  final Map<String, List<int>> cardNumbersByDriverId;
  final String searchQuery;
  final bool isRefreshing;

  /// Bumps after each successful valets+assignments fetch (list keys).
  final int dataRevision;

  const OperatorCardsReady({
    required this.valets,
    required this.cardNumbersByDriverId,
    required this.searchQuery,
    this.isRefreshing = false,
    this.dataRevision = 0,
  });

  OperatorCardsReady copyWith({
    List<ValetResponse>? valets,
    Map<String, List<int>>? cardNumbersByDriverId,
    String? searchQuery,
    bool? isRefreshing,
    int? dataRevision,
  }) {
    return OperatorCardsReady(
      valets: valets ?? this.valets,
      cardNumbersByDriverId:
          cardNumbersByDriverId ?? this.cardNumbersByDriverId,
      searchQuery: searchQuery ?? this.searchQuery,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      dataRevision: dataRevision ?? this.dataRevision,
    );
  }

  @override
  List<Object?> get props => [
        valets,
        cardNumbersByDriverId,
        searchQuery,
        isRefreshing,
        dataRevision,
      ];
}
