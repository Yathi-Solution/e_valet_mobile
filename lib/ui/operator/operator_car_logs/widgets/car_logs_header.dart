import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:evalet/services/translations/app_translations_notifier.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/text_constants.dart';
import 'package:evalet/ui/common/widgets/text.dart';

/// Top of the car logs screen: back button, title with the total count, and
/// the search box.
class CarLogsHeader extends StatelessWidget {
  const CarLogsHeader({
    super.key,
    required this.total,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchQuery,
    required this.onBack,
    required this.onSearch,
    required this.onQueryChanged,
    required this.onClear,
  });

  final int total;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;

  /// The current query; the clear button shows while it is not empty.
  final String searchQuery;
  final VoidCallback onBack;

  /// Runs the search with the text currently in the box.
  final VoidCallback onSearch;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.black,
          onPressed: () {
            onBack();
          },
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextComponent(
                labelText: '${t.get(TextConstants.carLogsTitle)} (${total})',
                color: AppColors.black,
                fontSize: MediaQuery.of(context).size.width *
                    (Platform.isIOS ? 0.026 : 0.03),
                fontWeight: FontWeight.bold,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              TextComponent(
                labelText: t.getByKey(
                    'carLogsDescription', TextConstants.carLogsDescription),
                color: AppColors.mutedText,
                fontSize: MediaQuery.of(context).size.width *
                    (Platform.isIOS ? 0.018 : 0.02),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width:
              MediaQuery.of(context).size.width * (Platform.isIOS ? 0.32 : 0.4),
          child: TextField(
            controller: searchController,
            focusNode: searchFocusNode,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            onChanged: (value) {
              onQueryChanged(value.trim());
              // Search when user types a space (after a word)
              if (value.endsWith(' ')) {
                onSearch();
              }
            },
            decoration: InputDecoration(
              hintText: t.getByKey(
                  'carLogsSearchHint', TextConstants.carLogsSearchHint),
              hintStyle: TextStyle(
                color: AppColors.mutedText,
                fontSize: MediaQuery.of(context).size.width * 0.02,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.primary,
                size: MediaQuery.of(context).size.width * 0.02,
              ),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: AppColors.mutedText,
                        size: MediaQuery.of(context).size.width * 0.02,
                      ),
                      onPressed: onClear,
                    )
                  : null,
              contentPadding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.02,
                vertical: MediaQuery.of(context).size.height * 0.01,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.grey.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.grey.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.02,
              color: AppColors.black,
            ),
          ),
        ),
      ],
    );
  }
}
