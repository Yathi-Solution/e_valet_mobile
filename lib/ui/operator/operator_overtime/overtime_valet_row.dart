import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/utils/duration_utils.dart';
import 'package:niloufer_valet_mobile/utils/valet_utils.dart';

/// Single valet row for the overtime screen: name, phone, status, minutes input, and submit.
class OvertimeValetRow extends StatefulWidget {
  final String name;
  final String phone;
  final String status;
  final int overtimeGrantedTotalMinutes;
  final int overtimeGrantsCount;
  final String latestOvertimeExpiryLabel;

  /// Total overtime minutes (hours+minutes combined).
  final int totalMinutes;
  final ValueChanged<int> onChanged;
  final VoidCallback onSubmit;

  const OvertimeValetRow({
    super.key,
    required this.name,
    required this.phone,
    required this.status,
    required this.overtimeGrantedTotalMinutes,
    required this.overtimeGrantsCount,
    required this.latestOvertimeExpiryLabel,
    required this.totalMinutes,
    required this.onChanged,
    required this.onSubmit,
  });

  @override
  State<OvertimeValetRow> createState() => _OvertimeValetRowState();
}

class _OvertimeValetRowState extends State<OvertimeValetRow> {
  static const int _maxHours = 24;
  int _selectedHours = 0;
  int _selectedMinutes = 0;
  late final TextEditingController _hoursController;
  late final TextEditingController _minutesController;
  late final FocusNode _minutesFocusNode;
  late final FocusNode _submitFocusNode;
  bool _suppressControllerListeners = false;

  int get _totalMinutes => (_selectedHours * 60) + _selectedMinutes;

  void _syncFromTotalMinutes(int totalMinutes) {
    final split = DurationUtils.splitToHoursMinutes(totalMinutes);
    _selectedHours = split.hours;
    _selectedMinutes = split.minutes;

    _suppressControllerListeners = true;
    _hoursController.text = _selectedHours.toString();
    _minutesController.text = _selectedMinutes.toString().padLeft(2, '0');
    _suppressControllerListeners = false;
  }

  void _emitChange() {
    widget.onChanged(_totalMinutes);
  }

  void _normalizeAndEmit() {
    // Normalize minutes >= 60 into hours.
    if (_selectedMinutes >= 60) {
      _selectedHours += _selectedMinutes ~/ 60;
      _selectedMinutes = _selectedMinutes % 60;
    }
    // Normalize negative minutes by borrowing from hours.
    while (_selectedMinutes < 0 && _selectedHours > 0) {
      _selectedHours -= 1;
      _selectedMinutes += 60;
    }
    if (_selectedHours < 0) _selectedHours = 0;
    if (_selectedHours > _maxHours) _selectedHours = _maxHours;
    if (_selectedMinutes < 0) _selectedMinutes = 0;

    _suppressControllerListeners = true;
    _hoursController.value = _hoursController.value.copyWith(
      text: _selectedHours.toString(),
      selection:
          TextSelection.collapsed(offset: _selectedHours.toString().length),
      composing: TextRange.empty,
    );
    final minutesText = _selectedMinutes.toString().padLeft(2, '0');
    _minutesController.value = _minutesController.value.copyWith(
      text: minutesText,
      selection: TextSelection.collapsed(offset: minutesText.length),
      composing: TextRange.empty,
    );
    _suppressControllerListeners = false;

    _emitChange();
  }

  void _applyHoursDelta(int delta) {
    setState(() {
      _selectedHours = (_selectedHours + delta);
      _normalizeAndEmit();
    });
  }

  void _applyMinutesDelta(int delta) {
    setState(() {
      _selectedMinutes = (_selectedMinutes + delta);
      _normalizeAndEmit();
    });
  }

  Widget _buildStepper({
    required VoidCallback onUp,
    required VoidCallback onDown,
  }) {
    return Container(
      width: 42,
      height: 46,
      child: Column(
        children: [
          Expanded(
            child: IconButton(
              icon: const Icon(Icons.keyboard_arrow_up),
              onPressed: onUp,
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: 42,
                height: 23,
              ),
            ),
          ),
          Container(
            height: 1,
            color: AppColors.grey.withOpacity(0.25),
          ),
          Expanded(
            child: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: onDown,
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: 42,
                height: 23,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required VoidCallback onUp,
    required VoidCallback onDown,
  }) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      counterText: '',
      suffixIconConstraints:
          const BoxConstraints.tightFor(width: 42, height: 46),
      suffixIcon: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.grey.withOpacity(0.25)),
          ),
        ),
        child: _buildStepper(onUp: onUp, onDown: onDown),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _hoursController = TextEditingController();
    _minutesController = TextEditingController();
    _minutesFocusNode = FocusNode();
    _submitFocusNode = FocusNode();
    _syncFromTotalMinutes(widget.totalMinutes);
  }

  @override
  void didUpdateWidget(OvertimeValetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalMinutes != widget.totalMinutes &&
        widget.totalMinutes != _totalMinutes) {
      setState(() {
        _syncFromTotalMinutes(widget.totalMinutes);
      });
    }
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _minutesFocusNode.dispose();
    _submitFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final screenWidth = MediaQuery.of(context).size.width;
    final nameFontSize = (screenWidth * 0.04).clamp(16.0, 20.0);
    final phoneFontSize = (screenWidth * 0.032).clamp(14.0, 18.0);
    final statusColor = ValetUtils.getStatusColor(widget.status);
    final statusLabel = ValetUtils.translatedStatusLabel(widget.status, t);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextComponent(
                      labelText: widget.name,
                      fontSize: nameFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    TextComponent(
                      labelText: widget.phone,
                      fontSize: phoneFontSize,
                      color: AppColors.mutedText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.overtimeGrantsCount > 0) ...[
                      const SizedBox(height: 4),
                      TextComponent(
                        labelText:
                            '${t.getByKey('overtimeGranted', TextConstants.overtimeGranted)}: ${DurationUtils.formatCompactHoursMinutes(widget.overtimeGrantedTotalMinutes)}',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.latestOvertimeExpiryLabel.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        TextComponent(
                          labelText:
                              '${t.getByKey('overtimeExpiresAt', TextConstants.overtimeExpiresAt)}: ${widget.latestOvertimeExpiryLabel}',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.mutedText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: statusColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: TextComponent(
                  labelText: statusLabel,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const gapBetweenPickers = 8.0;
              const submitMinWidth = 110.0;
              const minFieldWidth = 130.0;

              final requiredSingleRowWidth =
                  (minFieldWidth * 2) + gapBetweenPickers + submitMinWidth;
              final useTwoRows = constraints.maxWidth < requiredSingleRowWidth;

              Widget buildHoursField({required double width}) {
                return SizedBox(
                  width: width,
                  child: TextField(
                    controller: _hoursController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: _inputDecoration(
                      labelText: t.getByKey('hours', TextConstants.hours),
                      onUp: () => _applyHoursDelta(1),
                      onDown: () => _applyHoursDelta(-1),
                    ),
                    maxLength: 2,
                    onChanged: (v) {
                      if (_suppressControllerListeners) return;
                      final parsed = (int.tryParse(v) ?? 0).clamp(0, _maxHours);
                      setState(() => _selectedHours = parsed);
                      _normalizeAndEmit();
                    },
                    onSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_minutesFocusNode);
                    },
                  ),
                );
              }

              Widget buildMinutesField({required double width}) {
                return SizedBox(
                  width: width,
                  child: TextField(
                    controller: _minutesController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    focusNode: _minutesFocusNode,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: _inputDecoration(
                      labelText: t.getByKey('minutes', TextConstants.minutes),
                      onUp: () => _applyMinutesDelta(1),
                      onDown: () => _applyMinutesDelta(-1),
                    ),
                    maxLength: 3,
                    onChanged: (v) {
                      if (_suppressControllerListeners) return;
                      final parsed = int.tryParse(v) ?? 0;
                      setState(() => _selectedMinutes = parsed);
                      _normalizeAndEmit();
                    },
                    onSubmitted: (_) {
                      FocusScope.of(context).unfocus();
                      _submitFocusNode.requestFocus();
                      widget.onSubmit();
                    },
                  ),
                );
              }

              final fieldWidth = useTwoRows
                  ? ((constraints.maxWidth - gapBetweenPickers) / 2)
                      .clamp(120.0, 160.0)
                  : minFieldWidth;

              final submitButton = SizedBox(
                width: useTwoRows ? double.infinity : submitMinWidth,
                child: Focus(
                  focusNode: _submitFocusNode,
                  child: ElevatedButton(
                    onPressed: widget.onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: TextComponent(
                      labelText: t.getByKey(
                          'submitButton', TextConstants.submitButton),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              );

              if (useTwoRows) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        buildHoursField(width: fieldWidth),
                        const SizedBox(width: gapBetweenPickers),
                        buildMinutesField(width: fieldWidth),
                      ],
                    ),
                    const SizedBox(height: 10),
                    submitButton,
                  ],
                );
              }

              return Row(
                children: [
                  buildHoursField(width: fieldWidth),
                  const SizedBox(width: gapBetweenPickers),
                  buildMinutesField(width: fieldWidth),
                  const Spacer(),
                  submitButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
