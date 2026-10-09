import 'package:equatable/equatable.dart';

abstract class PreviewCarEvent extends Equatable {
  const PreviewCarEvent();

  @override
  List<Object?> get props => [];
}

class SubmitPhotoRequested extends PreviewCarEvent {
  final String? imagePath;
  final String? sessionId;
  final bool isReparking;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String? parkingLocation;
  final String? vehicleNumber;
  final int? cardNumber;
  /// When true, scanner/check-in API already succeeded; only park API should sync.
  final bool checkinSubmittedOnServer;

  const SubmitPhotoRequested({
    this.imagePath,
    this.sessionId,
    this.isReparking = false,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.parkingLocation,
    this.vehicleNumber,
    this.cardNumber,
    this.checkinSubmittedOnServer = false,
  }) : assert(
          imagePath != null || parkingLocation != null,
          'Either imagePath or parkingLocation must be provided',
        );

  @override
  List<Object?> get props => [
        imagePath,
        sessionId,
        isReparking,
        latitude,
        longitude,
        accuracy,
        parkingLocation,
        vehicleNumber,
        cardNumber,
        checkinSubmittedOnServer,
      ];
}

class ResetSubmission extends PreviewCarEvent {
  const ResetSubmission();
}
