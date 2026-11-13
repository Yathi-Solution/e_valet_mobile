import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:evalet/bloc/qr/qr_event.dart';
import 'package:evalet/bloc/qr/qr_state.dart';
import 'package:evalet/models/driver/qr/qr_data.dart';
import 'package:evalet/ui/common/text_constants.dart';
import 'package:evalet/utils/whatsapp_qr_parser.dart';

class QrBloc extends Bloc<QrEvent, QrState> {
  QrBloc() : super(const QrState()) {
    on<QrCodeDetected>(_onQrCodeDetected);
    on<QrResetRequested>(_onResetRequested);
    on<QrCameraActivateRequested>(_onCameraActivateRequested);
    // Rescan button: clear data and turn camera back on
    on<QrClearForRescan>(_onClearForRescan);
  }

  Future<void> _onQrCodeDetected(
    QrCodeDetected event,
    Emitter<QrState> emit,
  ) async {
    // If already processing or scanner is stopped, ignore new scans
    if (state.isProcessing || state.shouldStopScanner) return;

    emit(state.copyWith(
      scannedCode: event.code,
      qrData: null,
      customerCardNumber: null,
      isProcessing: true,
      successMessage: null,
      errorMessage: null,
      shouldStopScanner: false,
      cameraShouldBeActive: false, // Stop camera while processing
    ));

    final raw = event.code.trim();

    // First, try to parse as WhatsApp QR code (customer card)
    final customerCardNumber = tryParseCardNumberFromWhatsAppUrl(raw);
    if (customerCardNumber != null) {
      // Successfully parsed customer QR code
      final outletId = int.parse(dotenv.env['OUTLET_ID']!);
      final qrData = QrData(
        outletId: outletId,
        cardNumber: customerCardNumber,
        // Sent at check-in so the server can refuse a card of another outlet.
        outletCode: tryParseOutletCodeFromWhatsAppUrl(raw),
      );

      emit(state.copyWith(
        scannedCode: event.code,
        qrData: qrData,
        customerCardNumber: customerCardNumber,
        isProcessing: false,
        successMessage: 'Customer card scanned successfully',
        errorMessage: null,
        shouldStopScanner: true,
        cameraShouldBeActive: false,
      ));
      return;
    }

    // If not a WhatsApp QR, check if it's a valet QR code (JSON format)
    try {
      final jsonData = jsonDecode(raw) as Map<String, dynamic>;
      final qrData = QrData.fromJson(jsonData);

      // If JSON parsing succeeds, it's a valet card - show error
      emit(state.copyWith(
        scannedCode: event.code,
        qrData: null,
        customerCardNumber: null,
        isProcessing: false,
        successMessage: null,
        errorMessage: TextConstants.validationScanCustomerCardOnly,
        shouldStopScanner: true,
        cameraShouldBeActive: false,
      ));
      return;
    } catch (_) {
      // Neither WhatsApp nor JSON format - show generic error
      emit(state.copyWith(
        scannedCode: event.code,
        qrData: null,
        customerCardNumber: null,
        isProcessing: false,
        successMessage: null,
        errorMessage: 'Invalid QR code format. Please scan a customer card.',
        shouldStopScanner: true,
        cameraShouldBeActive: false,
      ));
    }
  }

  void _onResetRequested(
    QrResetRequested event,
    Emitter<QrState> emit,
  ) {
    // Clear state and stop camera so resources are released when leaving Scan tab
    emit(const QrState(
      cameraShouldBeActive: false,
    ));
  }

  void _onCameraActivateRequested(
    QrCameraActivateRequested event,
    Emitter<QrState> emit,
  ) {
    emit(state.copyWith(cameraShouldBeActive: true));
  }

  void _onClearForRescan(
    QrClearForRescan event,
    Emitter<QrState> emit,
  ) {
    // Clear scanned data and turn camera back on so user can scan again
    emit(const QrState(
      cameraShouldBeActive: true,
    ));
  }
}
