import 'package:equatable/equatable.dart';
import 'package:evalet/models/driver/qr/qr_data.dart';

class QrState extends Equatable {
  final String? scannedCode;
  final QrData? qrData;
  final int? customerCardNumber; // For WhatsApp QR codes
  final bool isProcessing;
  final String? successMessage;
  final String? errorMessage;
  final bool shouldStopScanner;
  final bool cameraShouldBeActive;

  const QrState({
    this.scannedCode,
    this.qrData,
    this.customerCardNumber,
    this.isProcessing = false,
    this.successMessage,
    this.errorMessage,
    this.shouldStopScanner = false,
    this.cameraShouldBeActive = true, // Camera active by default when no data
  });

  QrState copyWith({
    String? scannedCode,
    QrData? qrData,
    int? customerCardNumber,
    bool? isProcessing,
    String? successMessage,
    String? errorMessage,
    bool? shouldStopScanner,
    bool? cameraShouldBeActive,
  }) {
    return QrState(
      scannedCode: scannedCode ?? this.scannedCode,
      qrData: qrData ?? this.qrData,
      customerCardNumber: customerCardNumber ?? this.customerCardNumber,
      isProcessing: isProcessing ?? this.isProcessing,
      successMessage: successMessage,
      errorMessage: errorMessage,
      shouldStopScanner: shouldStopScanner ?? this.shouldStopScanner,
      cameraShouldBeActive: cameraShouldBeActive ?? this.cameraShouldBeActive,
    );
  }

  @override
  List<Object?> get props => [
        scannedCode,
        qrData,
        customerCardNumber,
        isProcessing,
        successMessage,
        errorMessage,
        shouldStopScanner,
        cameraShouldBeActive,
      ];
}
