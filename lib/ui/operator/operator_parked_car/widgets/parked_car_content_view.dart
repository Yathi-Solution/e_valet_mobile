import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/digital_key_rack_response.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/key_rack_item.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_parked_car/widgets/parked_car_card.dart';

class ParkedCarContentView extends StatefulWidget {
  final DigitalKeyRackResponse digitalKeyRack;
  final String searchQuery;
  final Function(int cardNumber, String sessionId)? onManualRequest;

  /// When false (e.g. auto mode enabled), manual request button is disabled.
  final bool manualRequestEnabled;

  const ParkedCarContentView({
    super.key,
    required this.digitalKeyRack,
    required this.searchQuery,
    this.onManualRequest,
    this.manualRequestEnabled = true,
  });

  @override
  State<ParkedCarContentView> createState() => _ParkedCarContentViewState();
}

class _ParkedCarContentViewState extends State<ParkedCarContentView> {
  List<KeyRackItem> _getFilteredAndSortedItems() {
    final items = widget.digitalKeyRack.keyRack;

    if (widget.searchQuery.isEmpty) {
      return items;
    }

    // Separate matching and non-matching items
    final matching = <KeyRackItem>[];
    final nonMatching = <KeyRackItem>[];

    for (final item in items) {
      if (item.cardNumber.toString().contains(widget.searchQuery)) {
        matching.add(item);
      } else {
        nonMatching.add(item);
      }
    }

    // Return matching items first, then non-matching
    return [...matching, ...nonMatching];
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final occupiedSlots = widget.digitalKeyRack.keyRack.length;
    final filteredItems = _getFilteredAndSortedItems();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Occupied Slots Grid
        if (occupiedSlots > 0) ...[
          // Show search results info if searching
          if (widget.searchQuery.isNotEmpty) ...[
            TextComponent(
              labelText:
                  t.get(TextConstants.showingResultsFor(widget.searchQuery)),
              color: AppColors.mutedText,
              fontSize: screenWidth * 0.013,
              fontWeight: FontWeight.w500,
            ),
            SizedBox(height: screenHeight * 0.015),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              // iOS only: 2 columns on narrow screens so each card has more width (avoids overflow). Android/others: always 4.
              final crossAxisCount =
                  (Platform.isIOS && screenWidth < 600) ? 2 : 4;
              final spacing = screenWidth * 0.02;
              final runSpacing = screenHeight * 0.02;
              final itemWidth =
                  (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
                      crossAxisCount;
              return Wrap(
                spacing: spacing,
                runSpacing: runSpacing,
                children: [
                  for (var i = 0; i < filteredItems.length; i++) ...[
                    SizedBox(
                      width: itemWidth,
                      child: ParkedCarCard(
                        item: filteredItems[i],
                        onManualRequest: widget.onManualRequest,
                        manualRequestEnabled: widget.manualRequestEnabled,
                        isHighlighted: widget.searchQuery.isNotEmpty &&
                            filteredItems[i]
                                .cardNumber
                                .toString()
                                .contains(widget.searchQuery),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ] else ...[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.1,
                ),
                Icon(
                  Icons.check_circle_outline,
                  size: MediaQuery.of(context).size.width * 0.06,
                  color: AppColors.mutedText,
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.02,
                ),
                TextComponent(
                  labelText: t.get(TextConstants.noCarsParked),
                  fontSize: MediaQuery.of(context).size.width * 0.018,
                  color: AppColors.mutedText,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
