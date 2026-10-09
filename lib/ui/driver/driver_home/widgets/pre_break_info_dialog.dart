import 'package:flutter/material.dart';
import 'package:niloufer_valet_mobile/api/driver/pass_parked_sessions_api_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/driver/pre_break/pre_break_info_response.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:provider/provider.dart';

class PreBreakInfoDialog extends StatefulWidget {
  final PreBreakInfoResponse info;

  const PreBreakInfoDialog({
    super.key,
    required this.info,
  });

  static Future<PreBreakDriverInfo?> show(
    BuildContext context, {
    String? title,
    String? actionLabel,
    required PreBreakInfoResponse info,
  }) {
    return showDialog<PreBreakDriverInfo>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PreBreakInfoDialog(info: info),
    );
  }

  @override
  State<PreBreakInfoDialog> createState() => _PreBreakInfoDialogState();
}

class _PreBreakInfoDialogState extends State<PreBreakInfoDialog> {
  String? _selectedDriverUserId;
  bool _isSubmitting = false;

  List<int> get _retrievalCardNumbers {
    final cards = <int>{};
    for (final r in widget.info.activeRetrievals) {
      if (r.cardNumber > 0) {
        cards.add(r.cardNumber);
      }
    }
    final out = cards.toList()..sort();
    return out;
  }

  List<int> get _parkedCardNumbers {
    final cards = <int>{};
    for (final s in widget.info.blockingSessions) {
      if (s.cardNumber > 0) {
        cards.add(s.cardNumber);
      }
    }
    final out = cards.toList()..sort();
    return out;
  }

  List<String> get _activeRetrievalSessionIds {
    final merged = <String>{
      ...widget.info.activeRetrievals
          .map((e) => e.sessionId.trim())
          .where((e) => e.isNotEmpty),
    };
    return merged.toList(growable: false);
  }

  Widget _buildCardChipsSection(
    BuildContext context, {
    required String title,
    required List<int> cards,
    required double screenWidth,
  }) {
    if (cards.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextComponent(
          labelText: title,
          fontSize: screenWidth * 0.036,
          fontWeight: FontWeight.w700,
          color: AppColors.black,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cards
              .map(
                (card) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.45),
                    ),
                  ),
                  child: TextComponent(
                    labelText: card.toString(),
                    fontSize: screenWidth * 0.033,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  PreBreakDriverInfo? get _selectedDriver {
    final selectedId = _selectedDriverUserId;
    if (selectedId == null || selectedId.isEmpty) return null;
    for (final driver in widget.info.availableDrivers) {
      if (driver.driverUserId == selectedId) return driver;
    }
    return null;
  }

  List<String> get _sessionIdsToPass {
    final merged = <String>{
      ...widget.info.blockingSessions
          .map((e) => e.sessionId.trim())
          .where((e) => e.isNotEmpty),
      ..._activeRetrievalSessionIds,
    };
    return merged.toList(growable: false);
  }

  Future<void> _onSelectDriverTap() async {
    if (_isSubmitting) return;
    final selectedDriver = _selectedDriver;
    if (selectedDriver == null) return;

    setState(() => _isSubmitting = true);
    try {
      final allSessionIds = _sessionIdsToPass;
      if (allSessionIds.isNotEmpty) {
        await PassParkedSessionsApiService.passParkedSessions(
          sessionIds: allSessionIds,
          passedToDriverUserId: selectedDriver.driverUserId,
        );
      }

      if (allSessionIds.isEmpty) {
        throw ApiException(
          'No pending work available to pass.',
          code: 'no_work',
        );
      }

      if (!mounted) return;

      SnackBars.showSuccessSnackBar(
        context,
        'Work passed successfully.',
      );
      Navigator.of(context).pop(selectedDriver);
    } on ApiException catch (e) {
      if (!mounted) return;
      print(
        '🟡 PREBREAK DIALOG passParkedSessions ApiException: code=${e.code} message=${e.message}',
      );
      SnackBars.showErrorSnackBar(context, e.message);
    } catch (e) {
      if (!mounted) return;
      print('🟡 PREBREAK DIALOG passParkedSessions unknown error: $e');
      SnackBars.showErrorSnackBar(
        context,
        'Failed to pass parked sessions. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final retrievalCards = _retrievalCardNumbers;
    final parkedCards = _parkedCardNumbers;
    final availableDrivers = widget.info.availableDrivers;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      actionsPadding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.assignment_late_outlined,
              color: AppColors.black,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextComponent(
              labelText: t.getByKey(
                'pendingWorkDetailsTitle',
                TextConstants.pendingWorkDetailsTitle,
              ),
              fontSize: screenWidth * 0.043,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: screenWidth * 0.86,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.62,
          ),
          child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (retrievalCards.isNotEmpty) ...[
                _buildCardChipsSection(
                  context,
                  title: 'Retrieval card numbers',
                  cards: retrievalCards,
                  screenWidth: screenWidth,
                ),
                const SizedBox(height: 12),
              ],
              if (parkedCards.isNotEmpty) ...[
                _buildCardChipsSection(
                  context,
                  title: 'Parked card numbers',
                  cards: parkedCards,
                  screenWidth: screenWidth,
                ),
              ],
              if ((retrievalCards.isNotEmpty || parkedCards.isNotEmpty) &&
                  availableDrivers.isNotEmpty)
                const SizedBox(height: 14),
              if (availableDrivers.isNotEmpty) ...[
                TextComponent(
                  labelText: t.getByKey(
                    'pendingWorkAvailableDriversLabel',
                    TextConstants.pendingWorkAvailableDriversLabel,
                  ),
                  fontSize: screenWidth * 0.036,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
                const SizedBox(height: 8),
                ...availableDrivers.map(
                  (driver) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          _selectedDriverUserId = driver.driverUserId;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedDriverUserId == driver.driverUserId
                              ? AppColors.primary.withOpacity(0.15)
                              : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedDriverUserId == driver.driverUserId
                                ? AppColors.primary
                                : AppColors.greyLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedDriverUserId == driver.driverUserId
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color:
                                  _selectedDriverUserId == driver.driverUserId
                                      ? AppColors.primary
                                      : AppColors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextComponent(
                                labelText: driver.name.isEmpty
                                    ? driver.driverUserId
                                    : driver.name,
                                fontSize: screenWidth * 0.034,
                                color: AppColors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.primary.withOpacity(0.6)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          child: TextComponent(
            labelText: t.get(TextConstants.close),
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        ElevatedButton(
          onPressed: (_selectedDriver == null || _isSubmitting)
              ? null
              : _onSelectDriverTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnDark,
            disabledBackgroundColor: AppColors.greyLight,
            disabledForegroundColor: AppColors.mutedText,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.textOnDark),
                  ),
                )
              : TextComponent(
                  labelText: t.getByKey(
                    'pendingWorkSelectDriver',
                    TextConstants.pendingWorkSelectDriver,
                  ),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textOnDark,
                ),
        ),
      ],
    );
  }
}
