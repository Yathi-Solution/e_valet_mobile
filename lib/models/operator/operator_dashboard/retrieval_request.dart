import 'package:evalet/models/operator/operator_dashboard/assigned_to.dart';
import 'package:evalet/models/operator/operator_dashboard/parked_by.dart';
import 'package:evalet/models/operator/operator_dashboard/vehicle.dart';

class RetrievalRequest {
  final String sessionId;
  final int cardNumber;
  final String requestType;
  final bool isManualRequest;
  final String waitingTime;
  final String requestedAt;
  final Vehicle vehicle;
  final ParkedBy parkedBy;
  final String status;
  final AssignedTo assignedTo;

  RetrievalRequest({
    required this.sessionId,
    required this.cardNumber,
    required this.requestType,
    required this.waitingTime,
    required this.requestedAt,
    required this.vehicle,
    required this.parkedBy,
    required this.isManualRequest,
    required this.status,
    required this.assignedTo,
  });

  RetrievalRequest copyWith({String? status, AssignedTo? assignedTo}) {
    return RetrievalRequest(
      sessionId: sessionId,
      cardNumber: cardNumber,
      requestType: requestType,
      isManualRequest: isManualRequest,
      waitingTime: waitingTime,
      requestedAt: requestedAt,
      vehicle: vehicle,
      parkedBy: parkedBy,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }

  factory RetrievalRequest.fromJson(Map<String, dynamic> json) {
    return RetrievalRequest(
      sessionId: json['sessionId'] ?? '',
      cardNumber: json['cardNumber'] ?? 0,
      requestType: json['requestType'] ?? '',
      waitingTime: json['waitingTime'] ?? '',
      requestedAt: json['requestedAt'] ?? '',
      vehicle: Vehicle.fromJson(json['vehicle'] ?? {}),
      parkedBy: ParkedBy.fromJson(json['parkedBy'] ?? {}),
      isManualRequest: json['isManualRequest'] ?? false,
      status: json['status'] ?? '',
      assignedTo: AssignedTo.fromJson(json['assignedTo'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'cardNumber': cardNumber,
      'requestType': requestType,
      'waitingTime': waitingTime,
      'requestedAt': requestedAt,
      'vehicle': vehicle.toJson(),
      'parkedBy': parkedBy.toJson(),
      'isManualRequest': isManualRequest,
      'status': status,
      'assignedTo': assignedTo.toJson(),
    };
  }
}
