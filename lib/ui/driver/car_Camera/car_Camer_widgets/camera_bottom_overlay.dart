import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/button_metrics.dart';
import 'package:niloufer_valet_mobile/ui/common/typography.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';

class CameraBottomOverlay extends StatefulWidget {
  final Function(BuildContext) onCapture;
  final Future<void> Function(BuildContext, String)? onSubmit;
  final bool positionAtTop;

  final String? initialParkingLocation;

  const CameraBottomOverlay({
    super.key,
    required this.onCapture,
    this.onSubmit,
    this.positionAtTop = false,
    this.initialParkingLocation,
  });

  @override
  State<CameraBottomOverlay> createState() => _CameraBottomOverlayState();
}

class _CameraBottomOverlayState extends State<CameraBottomOverlay> {
  final TextEditingController _parkingLocationController =
      TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitLoading = false;

  Future<void> _runSubmit(BuildContext context, String parkingLocation) async {
    if (_isSubmitLoading) return;
    final onSubmit = widget.onSubmit;
    if (onSubmit == null) return;
    setState(() => _isSubmitLoading = true);
    try {
      await onSubmit(context, parkingLocation);
    } finally {
      if (mounted) setState(() => _isSubmitLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialParkingLocation;
    if (initial != null && initial.isNotEmpty) {
      _parkingLocationController.text = initial;
    }
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: widget.positionAtTop
          ? (isKeyboardOpen ? keyboardHeight + screenHeight * 0.01 : 0.0)
          : (isKeyboardOpen ? null : screenHeight * 0.7),
      bottom: widget.positionAtTop
          ? null
          : (isKeyboardOpen ? keyboardHeight + screenHeight * 0.01 : 0.0),
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenHeight * 0.015,
        ),
        color: AppColors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextComponent(
              labelText: t.getByKey(
                'parkingLocationLabel',
                TextConstants.parkingLocationLabel,
              ),
              color: AppColors.nearBlack,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            const SizedBox(height: 6),
            Container(
              height: screenHeight * 0.06,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.coral, width: 1),
              ),
              child: TextField(
                controller: _parkingLocationController,
                focusNode: _focusNode,
                style: AppTypography.merge(
                  TextStyle(
                    color: AppColors.nearBlack,
                    fontSize: AppTypography.body,
                  ),
                ),
                decoration: InputDecoration(
                  hintText: t.getByKey(
                    'enterParkingLocationHint',
                    TextConstants.enterParkingLocationHint,
                  ),
                  hintStyle: AppTypography.merge(
                    TextStyle(
                      color: AppColors.mutedText,
                      fontSize: AppTypography.body,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03,
                    vertical: screenHeight * 0.018,
                  ),
                  border: InputBorder.none,
                ),
                maxLines: 1,
                textInputAction: TextInputAction.done,
                onSubmitted: (value) {
                  if (widget.onSubmit != null && value.trim().isNotEmpty) {
                    _runSubmit(context, value.trim());
                  }
                },
              ),
            ),
            SizedBox(height: screenHeight * 0.012),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitLoading
                    ? null
                    : () {
                        final parkingLocation =
                            _parkingLocationController.text.trim();
                        if (parkingLocation.isEmpty) {
                          SnackBars.showErrorSnackBar(
                            context,
                            t.getByKey(
                              'pleaseEnterParkingLocation',
                              TextConstants.pleaseEnterParkingLocation,
                            ),
                          );
                          return;
                        }
                        if (widget.onSubmit != null) {
                          _runSubmit(context, parkingLocation);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  minimumSize: Size(
                    double.infinity,
                    ButtonMetrics.cameraSubmitMinHeight(context),
                  ),
                  padding: ButtonMetrics.cameraSubmitPadding(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ButtonMetrics.cameraSubmitRadius,
                    ),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : Center(
                        child: TextComponent(
                          labelText: t.getByKey(
                            'submitButton',
                            TextConstants.submitButton,
                          ),
                          fontSize:
                              ButtonMetrics.cameraSubmitFontSize(context),
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _parkingLocationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
