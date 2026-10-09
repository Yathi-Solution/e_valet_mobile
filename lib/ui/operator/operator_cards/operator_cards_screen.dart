import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:niloufer_valet_mobile/bloc/operator/operator_cards/operator_cards_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/operator/operator_cards/operator_cards_event.dart';
import 'package:niloufer_valet_mobile/bloc/operator/operator_cards/operator_cards_state.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_valet/valet_response.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_cards/card_allocation_edit_dialog.dart';

/// Operator tab: list all drivers and assign **physical card numbers**
/// (e.g. 11, 12, 61) each driver may use.
class OperatorCardsScreen extends StatefulWidget {
  final Function(VoidCallback)? onRefreshReady;
  final Function(int)? onNavigateToTab;

  const OperatorCardsScreen({
    super.key,
    this.onRefreshReady,
    this.onNavigateToTab,
  });

  @override
  State<OperatorCardsScreen> createState() => _OperatorCardsScreenState();
}

List<ValetResponse> _filteredValets(
  List<ValetResponse> all,
  String query,
  Map<String, List<int>> cardNumbersByDriverId,
) {
  final q = query.toLowerCase().trim();
  if (q.isEmpty) return all;
  String digitsOnly(String input) => input.replaceAll(RegExp(r'\D'), '');

  if (RegExp(r'^\d+$').hasMatch(q)) {
    final asInt = int.tryParse(q);
    final byId = all.where((v) => v.userId.toLowerCase() == q).toList();
    final byCard = asInt == null
        ? <ValetResponse>[]
        : all.where((v) {
            final cards = cardNumbersByDriverId[v.userId] ?? [];
            return cards.contains(asInt);
          }).toList();
    final byPhone = all.where((v) {
      final phoneDigits = digitsOnly(v.phone);
      // Match by local number input without requiring country code (e.g. +91).
      return phoneDigits.endsWith(q) || phoneDigits.contains(q);
    }).toList();
    final seen = <String>{};
    final merged = <ValetResponse>[];
    for (final v in [...byId, ...byCard, ...byPhone]) {
      if (seen.add(v.userId)) merged.add(v);
    }
    return merged;
  }
  return all
      .where((v) =>
          v.name.toLowerCase().contains(q) ||
          v.phone.toLowerCase().contains(q) ||
          digitsOnly(v.phone).contains(digitsOnly(q)) ||
          v.userId.toLowerCase().contains(q))
      .toList();
}

String _formatNumbersPreview(List<int> nums, {int maxChars = 100}) {
  if (nums.isEmpty) return '';
  final s = nums.join(', ');
  if (s.length <= maxChars) return s;
  return '${s.substring(0, maxChars - 1)}…';
}

class _OperatorCardsScreenState extends State<OperatorCardsScreen> {
  final String _outletId = dotenv.env['OUTLET_ID'] ?? '1';
  final TextEditingController _searchController = TextEditingController();

  late final OperatorCardsBloc _cardsBloc;

  @override
  void initState() {
    super.initState();
    _cardsBloc = OperatorCardsBloc(outletId: _outletId)
      ..add(const OperatorCardsLoadRequested());
    _searchController.addListener(() {
      _cardsBloc.add(
        OperatorCardsSearchQueryChanged(_searchController.text.trim()),
      );
    });
    if (widget.onRefreshReady != null) {
      Future.microtask(() {
        widget.onRefreshReady?.call(() {
          _cardsBloc.add(const OperatorCardsRefreshRequested());
        });
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cardsBloc.close();
    super.dispose();
  }

  Future<void> _editAllocation(ValetResponse v) async {
    final t = context.read<AppTranslationsNotifier>();
    final s = _cardsBloc.state;
    final current = s is OperatorCardsReady
        ? (s.cardNumbersByDriverId[v.userId] ?? <int>[])
        : <int>[];
    final next = await showDialog<List<int>>(
      context: context,
      builder: (ctx) => CardAllocationEditDialog(
        driverName: v.name,
        driverUserId: v.userId,
        outletId: _outletId,
        initialCardNumbers: current,
        title: t.get(TextConstants.cardsEditAllocationTitle),
        hint: t.get(TextConstants.cardsAllocationHint),
        helperText: t.get(TextConstants.cardsAllocationHelper),
        saveLabel: t.get(TextConstants.cardsSaveAllocation),
        cancelLabel: t.get(TextConstants.cancel),
      ),
    );
    if (next == null || !mounted) return;
    _cardsBloc.add(const OperatorCardsRefreshRequested());
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width * 0.04;

    return BlocProvider.value(
      value: _cardsBloc,
      child: BlocBuilder<OperatorCardsBloc, OperatorCardsState>(
        builder: (context, state) {
          if (state is OperatorCardsInitial || state is OperatorCardsLoading) {
            return const ColoredBox(
              color: AppColors.white,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          if (state is OperatorCardsLoadFailure) {
            return ColoredBox(
              color: AppColors.white,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontal),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextComponent(
                        labelText:
                            '${t.get(TextConstants.errorLabel)}: ${state.message}',
                        color: AppColors.error,
                        textAlign: TextAlign.center,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () =>
                            _cardsBloc.add(const OperatorCardsLoadRequested()),
                        child: TextComponent(
                          labelText: t.get(TextConstants.retryButton),
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final ready = state as OperatorCardsReady;
          final visible = _filteredValets(
            ready.valets,
            ready.searchQuery,
            ready.cardNumbersByDriverId,
          );

          return ColoredBox(
            color: AppColors.white,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          color: AppColors.black,
                          onPressed: () => widget.onNavigateToTab?.call(0),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextComponent(
                                labelText: t.getByKey(
                                  'cardsAllotmentTitle',
                                  TextConstants.cardsAllotmentTitle,
                                ),
                                color: AppColors.black,
                                fontSize: (width * 0.042).clamp(16.0, 22.0),
                                fontWeight: FontWeight.bold,
                              ),
                              const SizedBox(height: 2),
                              TextComponent(
                                labelText: t.getByKey(
                                  'cardsAssignToEachValet',
                                  TextConstants.cardsAssignToEachValet,
                                ),
                                color: AppColors.mutedText,
                                fontSize: (width * 0.03).clamp(12.0, 14.0),
                                fontWeight: FontWeight.w500,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: width * 0.4,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: t.getByKey(
                                'searchByNameOrCardNumber',
                                TextConstants.searchByNameOrCardNumber,
                              ),
                              hintStyle: TextStyle(
                                color: AppColors.mutedText,
                                fontSize: width * 0.02,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.primary,
                              ),
                              suffixIcon: ready.searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        color: AppColors.mutedText,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        FocusScope.of(context).unfocus();
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.grey.withOpacity(0.35),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.grey.withOpacity(0.35),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (ready.isRefreshing)
                    const LinearProgressIndicator(
                      minHeight: 2,
                      color: AppColors.primary,
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        _cardsBloc.add(const OperatorCardsRefreshRequested());
                        await _cardsBloc.stream.firstWhere(
                          (s) =>
                              s is OperatorCardsLoadFailure ||
                              (s is OperatorCardsReady && !s.isRefreshing),
                        );
                      },
                      child: visible.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.sizeOf(context).height * 0.15,
                                ),
                                Center(
                                  child: TextComponent(
                                    labelText:
                                        t.get(TextConstants.noValetsFound),
                                    color: AppColors.mutedText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: EdgeInsets.fromLTRB(
                                horizontal,
                                0,
                                horizontal,
                                24,
                              ),
                              itemCount: visible.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: AppColors.grey.withOpacity(0.25),
                              ),
                              itemBuilder: (context, index) {
                                final v = visible[index];
                                final nums =
                                    ready.cardNumbersByDriverId[v.userId] ??
                                        const <int>[];
                                final n = nums.length;
                                final countLabel = n == 0
                                    ? '—'
                                    : n == 1
                                        ? '1 ${t.get(TextConstants.cardSingular)}'
                                        : '$n ${t.get(TextConstants.cardsPlural)}';
                                return _DriverCardAllocationTile(
                                  key: ValueKey(
                                    '${v.userId}_${ready.dataRevision}',
                                  ),
                                  valet: v,
                                  hasNumbers: nums.isNotEmpty,
                                  numbersPreview: _formatNumbersPreview(nums),
                                  countLabel: countLabel,
                                  emptyNumbersLabel: t.get(
                                      TextConstants.cardsNoNumbersAssigned),
                                  onEdit: () => _editAllocation(v),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DriverCardAllocationTile extends StatelessWidget {
  final ValetResponse valet;
  final bool hasNumbers;
  final String numbersPreview;
  final String countLabel;
  final String emptyNumbersLabel;
  final VoidCallback onEdit;

  const _DriverCardAllocationTile({
    super.key,
    required this.valet,
    required this.hasNumbers,
    required this.numbersPreview,
    required this.countLabel,
    required this.emptyNumbersLabel,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        valet.name.trim().isNotEmpty ? valet.name.trim()[0].toUpperCase() : '?';
    final width = MediaQuery.sizeOf(context).width;
    final nameSize = (width * 0.04).clamp(16.0, 20.0);
    final subTextSize = (width * 0.034).clamp(13.0, 16.0);
    final countSize = (width * 0.038).clamp(15.0, 19.0);

    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.15),
              foregroundColor: AppColors.primary,
              child: TextComponent(
                labelText: initial,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextComponent(
                    labelText: valet.name,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                    fontSize: nameSize,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  TextComponent(
                    labelText: valet.phone,
                    color: AppColors.mutedText,
                    fontSize: subTextSize,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  TextComponent(
                    labelText: hasNumbers ? numbersPreview : emptyNumbersLabel,
                    color: hasNumbers ? AppColors.primary : AppColors.grey,
                    fontSize: subTextSize,
                    fontWeight: FontWeight.w500,
                    fontStyle: hasNumbers ? FontStyle.normal : FontStyle.italic,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.credit_card,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    TextComponent(
                      labelText: countLabel,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                      fontSize: countSize,
                    ),
                  ],
                ),
                IconButton(
                  onPressed: onEdit,
                  icon:
                      const Icon(Icons.edit_outlined, color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
