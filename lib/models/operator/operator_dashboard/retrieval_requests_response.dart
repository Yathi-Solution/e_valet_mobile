import 'package:evalet/models/operator/operator_dashboard/retrieval_request.dart';

class RetrievalRequestsResponse {
  final List<RetrievalRequest> requests;

  RetrievalRequestsResponse({required this.requests});

  factory RetrievalRequestsResponse.fromJson(Map<String, dynamic> json) {
    final requestsList = json['requests'] as List<dynamic>? ?? [];
    return RetrievalRequestsResponse(
      requests: requestsList
          .map((request) =>
              RetrievalRequest.fromJson(request as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requests': requests.map((request) => request.toJson()).toList(),
    };
  }
}
