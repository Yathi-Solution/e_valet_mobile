import 'package:flutter/material.dart';
import 'package:niloufer_valet_mobile/api/driver/my_cards_api_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/driver/cards/my_cards_response.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/custom_app_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:provider/provider.dart';

class MyCardsScreen extends StatefulWidget {
  const MyCardsScreen({super.key});

  @override
  State<MyCardsScreen> createState() => _MyCardsScreenState();
}

class _MyCardsScreenState extends State<MyCardsScreen> {
  late Future<MyCardsResponse> _cardsFuture;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _cardsFuture = MyCardsApiService.refreshAssignedCardsLocally();
  }

  Future<void> _refresh() async {
    final next = MyCardsApiService.refreshAssignedCardsLocally();
    setState(() {
      _cardsFuture = next;
    });
    await next;
  }

  /// Sync Cards action:
  /// 1. Remove old locally stored cards data.
  /// 2. Fetch fresh assignment from server.
  /// 3. Store the new data locally (replacing what was cleared).
  /// 4. Update the screen UI with the fresh data.
  Future<void> _syncCards() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    try {
      final fresh = await MyCardsApiService.refreshAssignedCardsLocally();

      if (!mounted) return;

      setState(() {
        _cardsFuture = Future.value(fresh);
        _isSyncing = false;
      });

      if (mounted) {
        final t = context.read<AppTranslationsNotifier>();
        final msg = t.get(TextConstants.cardsSyncedMessage);
        SnackBars.showSuccessSnackBar(
          context,
          msg.isNotEmpty ? msg : TextConstants.cardsSyncedMessage,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSyncing = false);

      final t = context.read<AppTranslationsNotifier>();
      SnackBars.showErrorSnackBar(
        context,
        getDisplayErrorMessage(e).isNotEmpty
            ? getDisplayErrorMessage(e)
            : t.get(TextConstants.errorLabel),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();

    return Scaffold(
      backgroundColor: AppColors.primarySurface,
      appBar: CustomAppBar(
        showOverflowMenu: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<MyCardsResponse>(
          future: _cardsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextComponent(
                        labelText: '${t.get(TextConstants.errorLabel)}',
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      TextComponent(
                        labelText: getDisplayErrorMessage(snapshot.error),
                        color: AppColors.mutedText,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refresh,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                        ),
                        child: TextComponent(
                          labelText: t.get(TextConstants.retryButton),
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = snapshot.data;
            if (data == null) {
              return const SizedBox.shrink();
            }

            try {
              final numbers = data.cards.map((c) => c.cardNumber).toList(growable: false);
              TokenStorage.saveDriverAssignedCardNumbers(numbers);
            } catch (_) {}

            final cards = data.cards.toList()
              ..sort((a, b) => a.cardNumber.compareTo(b.cardNumber));
            final count = cards.length;
            final countLabel = count == 1
                ? '1 ${t.get(TextConstants.cardSingular)}'
                : '$count ${t.get(TextConstants.cardsPlural)}';

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  TextComponent(
                    labelText: t.get(TextConstants.cards),
                    color: AppColors.bodyText,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSyncing ? null : _syncCards,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.headerDark,
                        foregroundColor: AppColors.textOnDark,
                        disabledBackgroundColor:
                            AppColors.grey.withOpacity(0.35),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isSyncing)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.textOnDark,
                              ),
                            )
                          else
                            const Icon(Icons.sync, size: 22),
                          const SizedBox(width: 10),
                          TextComponent(
                            labelText: t.get(TextConstants.syncCards),
                            color: AppColors.textOnDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextComponent(
                          labelText: data.outletName,
                          color: AppColors.black,
                          fontWeight: FontWeight.w600,
                        ),
                        const SizedBox(height: 6),
                        TextComponent(
                          labelText: countLabel,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (cards.isEmpty)
                    TextComponent(
                      labelText: t.get(TextConstants.cardsNoNumbersAssigned),
                      color: AppColors.mutedText,
                      fontStyle: FontStyle.italic,
                    )
                  else
                    ...cards.map(
                      (card) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          border: Border.all(
                            color: AppColors.grey.withOpacity(0.25),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.credit_card,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextComponent(
                                labelText:
                                    '${t.get(TextConstants.cardNumber)}: ${card.cardNumber}',
                                color: AppColors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
