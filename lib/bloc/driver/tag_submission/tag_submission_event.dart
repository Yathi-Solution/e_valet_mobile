import 'package:equatable/equatable.dart';
import 'package:evalet/models/driver/qr/qr_data.dart';

abstract class TagSubmissionEvent extends Equatable {
  const TagSubmissionEvent();

  @override
  List<Object?> get props => [];
}

class QrCodeSubmitted extends TagSubmissionEvent {
  final QrData qrData;

  const QrCodeSubmitted(this.qrData);

  @override
  List<Object?> get props => [qrData];
}

class TagNumberSubmitted extends TagSubmissionEvent {
  final int outletId;
  final int cardNumber;

  const TagNumberSubmitted({
    required this.outletId,
    required this.cardNumber,
  });

  @override
  List<Object?> get props => [outletId, cardNumber];
}

class TagSubmissionReset extends TagSubmissionEvent {
  const TagSubmissionReset();
}
