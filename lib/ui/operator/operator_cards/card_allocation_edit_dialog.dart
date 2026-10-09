import 'package:flutter/material.dart';
import 'package:niloufer_valet_mobile/api/operator/operator_cards/card_assignments_api_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_cards/card_numbers_input.dart';

/// Dialog to enter physical **card numbers** for one driver (not a total count).
/// On Save, calls [CardAssignmentsApiService.assignCardNumbersToDriver] (PATCH),
/// which sets the complete desired list for the driver (handles adds and removes),
/// then pops with the saved list on success.
class CardAllocationEditDialog extends StatefulWidget {
  final String driverName;
  final String driverUserId;

  /// Outlet id from env / app (string); sent as int in the JSON body.
  final String outletId;
  final List<int> initialCardNumbers;
  final String title;
  final String hint;
  final String helperText;
  final String saveLabel;
  final String cancelLabel;

  const CardAllocationEditDialog({
    super.key,
    required this.driverName,
    required this.driverUserId,
    required this.outletId,
    required this.initialCardNumbers,
    required this.title,
    required this.hint,
    required this.helperText,
    required this.saveLabel,
    required this.cancelLabel,
  });

  @override
  State<CardAllocationEditDialog> createState() =>
      _CardAllocationEditDialogState();
}

class _CardAllocationEditDialogState extends State<CardAllocationEditDialog> {
  late final TextEditingController _controller;
  String? _parseError;
  String? _apiError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: formatCardNumbersForEditing(widget.initialCardNumbers),
    );
    _controller.addListener(() {
      if (_parseError != null || _apiError != null) {
        setState(() {
          _parseError = null;
          _apiError = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final parsed = parseCardNumbersInput(_controller.text);
    if (parsed.error != null) {
      setState(() {
        _parseError = parsed.error;
        _apiError = null;
      });
      return;
    }

    setState(() {
      _parseError = null;
      _apiError = null;
      _isSubmitting = true;
    });

    try {
      final initialSet = widget.initialCardNumbers.toSet();
      final editedSet = parsed.numbers.toSet();

      final removedCards = initialSet.difference(editedSet).toList();
      final addedCards = editedSet.difference(initialSet);
      final hasChanged = removedCards.isNotEmpty || addedCards.isNotEmpty;

      if (hasChanged) {
        // Use the PATCH endpoint to set the full desired cardNumbers for this driver.
        // The server computes added/removed internally.
        await CardAssignmentsApiService.assignCardNumbersToDriver(
          driverUserId: widget.driverUserId,
          outletId: widget.outletId,
          cardNumbers: parsed.numbers,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop<List<int>>(parsed.numbers);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _apiError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _apiError = getDisplayErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = (width * 0.04).clamp(15.0, 20.0);
    final bodySize = (width * 0.034).clamp(13.0, 16.0);
    final errorSize = (width * 0.03).clamp(12.0, 14.0);
    final buttonSize = (width * 0.033).clamp(12.0, 15.0);

    return AlertDialog(
      title: TextComponent(
        labelText: widget.title,
        fontSize: titleSize,
        fontWeight: FontWeight.w700,
        color: AppColors.black,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextComponent(
              labelText: widget.driverName,
              fontSize: bodySize,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            TextComponent(
              labelText: widget.helperText,
              fontSize: (width * 0.032).clamp(12.0, 14.0),
              color: AppColors.mutedText,
              fontWeight: FontWeight.w500,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.multiline,
              maxLines: 8,
              minLines: 4,
              style: TextStyle(
                fontSize: (width * 0.038).clamp(14.0, 17.0),
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(
                  fontSize: (width * 0.032).clamp(13.0, 15.0),
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w500,
                ),
                alignLabelWithHint: true,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_parseError != null) ...[
              const SizedBox(height: 10),
              TextComponent(
                labelText: _parseError!,
                fontSize: errorSize,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ],
            if (_apiError != null) ...[
              const SizedBox(height: 10),
              TextComponent(
                labelText: _apiError!,
                fontSize: errorSize,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ],
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        OutlinedButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: TextComponent(
            labelText: widget.cancelLabel,
            fontSize: buttonSize,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.grey.withValues(alpha: 0.35),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isSubmitting
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : TextComponent(
                  labelText: widget.saveLabel,
                  fontSize: buttonSize,
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
        ),
      ],
    );
  }
}
