import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:niloufer_valet_mobile/bloc/scanner/scanner_qr/scanner_qr_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/scanner/scanner_qr/scanner_qr_event.dart';
import 'package:niloufer_valet_mobile/bloc/scanner/scanner_qr/scanner_qr_state.dart';
import 'package:niloufer_valet_mobile/services/qr/valet_qr_scanner_controller_factory.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';

/// Dialog that shows a QR scanner. On scan of a WhatsApp URL (e.g. from
/// customer card), [ScannerQrBloc] extracts card number and calls manual
/// retrieval request API.
class ScannerQrDialog extends StatefulWidget {
  /// Returns when the dialog is closed. Snackbars are shown using the caller's
  /// context so messages remain visible after closing the dialog.
  ///
  /// Returns `true` if a QR was scanned and API call succeeded, otherwise `false`.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider(
        create: (_) => ScannerQrBloc(),
        child: ScannerQrDialog(parentContext: context),
      ),
    );
    return result ?? false;
  }

  final BuildContext parentContext;

  const ScannerQrDialog({
    super.key,
    required this.parentContext,
  });

  @override
  State<ScannerQrDialog> createState() => _ScannerQrDialogState();
}

class _ScannerQrDialogState extends State<ScannerQrDialog> {
  late final MobileScannerController _controller =
      createValetQrScannerController(autoStart: true);
  bool _isTorchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final value = barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;
    context.read<ScannerQrBloc>().add(ScannerQrCodeDetected(value));
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (!mounted) return;
      setState(() {
        _isTorchOn = !_isTorchOn;
      });
    } catch (_) {
      if (!mounted) return;
      final t = context.read<AppTranslationsNotifier>();
      SnackBars.showErrorSnackBar(
        widget.parentContext,
        t.get(TextConstants.errorTogglingFlash),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final size = MediaQuery.of(context).size;
    return BlocListener<ScannerQrBloc, ScannerQrState>(
      listener: (context, state) {
        if (state is ScannerQrSuccess) {
          SnackBars.showSuccessSnackBar(widget.parentContext, state.message);
          Navigator.of(context).pop(true);
        } else if (state is ScannerQrValetCardScanned) {
          SnackBars.showErrorSnackBar(widget.parentContext, state.message);
          Future<void>.delayed(const Duration(milliseconds: 150), () {
            if (context.mounted) Navigator.of(context).pop(false);
          });
        } else if (state is ScannerQrError) {
          SnackBars.showErrorSnackBar(widget.parentContext, state.message);
          Future<void>.delayed(const Duration(milliseconds: 150), () {
            if (context.mounted) Navigator.of(context).pop(false);
          });
        } else if (state is ScannerQrInvalidQr) {
          SnackBars.showErrorSnackBar(widget.parentContext, state.message);
          Future<void>.delayed(const Duration(milliseconds: 150), () {
            if (context.mounted) Navigator.of(context).pop(false);
          });
        }
      },
      child: BlocBuilder<ScannerQrBloc, ScannerQrState>(
        buildWhen: (prev, curr) =>
            (curr is ScannerQrProcessing) != (prev is ScannerQrProcessing),
        builder: (context, state) {
          final isProcessing = state is ScannerQrProcessing;
          return Dialog(
            backgroundColor: AppColors.primarySurface,
            insetPadding: EdgeInsets.symmetric(
              horizontal: size.width * 0.05,
              vertical: size.height * 0.1,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextComponent(
                        labelText: t.get(TextConstants.scanQr),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _isTorchOn ? Icons.flash_on : Icons.flash_off,
                              color: _isTorchOn
                                  ? AppColors.primary
                                  : AppColors.black,
                            ),
                            onPressed: isProcessing ? null : _toggleTorch,
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.close, color: AppColors.black),
                            onPressed: isProcessing
                                ? null
                                : () => Navigator.of(context).pop(false),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: size.width * 0.04,
                      top: size.height * 0.01,
                      right: size.width * 0.04,
                      bottom: 0,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: double.infinity,
                      height: size.height * 0.4,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          final h = constraints.maxHeight;
                          final side = math.min(w, h) * 0.88;
                          final scanWindow = Rect.fromCenter(
                            center: Offset(w / 2, h / 2),
                            width: side,
                            height: side,
                          );
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              MobileScanner(
                                controller: _controller,
                                scanWindow: scanWindow,
                                onDetect: _onDetect,
                                errorBuilder:
                                    (context, error, child) => Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: AppColors.error,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 8),
                                      TextComponent(
                                        labelText:
                                            t.get(TextConstants.cameraError),
                                        color: AppColors.black,
                                        fontSize: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isProcessing)
                                Container(
                                  color: AppColors.qrProcessingOverlay,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextComponent(
                    labelText: t.get(TextConstants.scanWhatsAppQrInstruction),
                    fontSize: 12,
                    color: AppColors.mutedText,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
