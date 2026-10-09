import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/cupertino_colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';

class BlockDropdownWidget extends StatefulWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String labelText;

  const BlockDropdownWidget({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelText = TextConstants.blockLabel,
  });

  @override
  State<BlockDropdownWidget> createState() => _BlockDropdownWidgetState();
}

class _BlockDropdownWidgetState extends State<BlockDropdownWidget> {
  static const List<String> _blockOptions = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'Club House',
    'Facility Office',
  ];

  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    // iOS uses Cupertino design
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _buildCupertinoDropdown(context, t);
    }

    // Android and other platforms use Material Design
    return _buildMaterialDropdown(context, t);
  }

  Widget _buildCupertinoDropdown(
      BuildContext context, AppTranslationsNotifier t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: TextComponent(
            labelText: widget.labelText,
            fontSize: 12,
            color: AppCupertinoColors.label(context),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppCupertinoColors.separator(context),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton2<String>(
            value: widget.value,
            isExpanded: true,
            hint: TextComponent(
              labelText: t.get(TextConstants.selectLabel(widget.labelText)),
              fontSize: 16,
              color: AppCupertinoColors.placeholderText(context),
            ),
            items: _blockOptions.map((String block) {
              return DropdownMenuItem<String>(
                value: block,
                child: TextComponent(
                  labelText: block,
                  fontSize: 16,
                ),
              );
            }).toList(),
            onChanged: widget.onChanged,
            buttonStyleData: ButtonStyleData(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppCupertinoColors.systemBackground(context),
              ),
            ),
            iconStyleData: IconStyleData(
              icon: Icon(
                CupertinoIcons.chevron_down,
                size: 20,
                color: AppCupertinoColors.label(context),
              ),
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppCupertinoColors.systemBackground(context),
              ),
              offset: const Offset(0, -8),
              scrollbarTheme: ScrollbarThemeData(
                radius: const Radius.circular(40),
                thickness: MaterialStateProperty.all(6),
                thumbVisibility: MaterialStateProperty.all(true),
              ),
            ),
            menuItemStyleData: const MenuItemStyleData(
              height: 40,
              padding: EdgeInsets.only(left: 16, right: 16),
            ),
            dropdownSearchData: DropdownSearchData(
              searchController: _searchController,
              searchInnerWidgetHeight: 50,
              searchInnerWidget: Container(
                height: 50,
                padding: const EdgeInsets.only(
                  top: 8,
                  bottom: 4,
                  right: 8,
                  left: 8,
                ),
                child: TextFormField(
                  expands: true,
                  maxLines: null,
                  controller: _searchController,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    hintText: t.get(TextConstants.searchBlockHint),
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppCupertinoColors.placeholderText(context),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppCupertinoColors.separator(context),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppCupertinoColors.separator(context),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppCupertinoColors.activeBlue,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              searchMatchFn: (item, searchValue) {
                return item.value?.toLowerCase().contains(
                          searchValue.toLowerCase(),
                        ) ??
                    false;
              },
            ),
            onMenuStateChange: (isOpen) {
              if (isOpen) {
                // Optional: Add haptic feedback for iOS
                // HapticFeedback.selectionClick();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialDropdown(
      BuildContext context, AppTranslationsNotifier t) {
    return DropdownButtonFormField2<String>(
      value: widget.value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: widget.labelText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      hint: TextComponent(
        labelText: t.get(TextConstants.selectLabel(widget.labelText)),
        fontSize: 16,
        color: AppColors.mutedText,
      ),
      items: _blockOptions.map((String block) {
        return DropdownMenuItem<String>(
          value: block,
          child: TextComponent(
            labelText: block,
            fontSize: 16,
            color: AppColors.black,
          ),
        );
      }).toList(),
      onChanged: widget.onChanged,
      buttonStyleData: ButtonStyleData(
        padding: const EdgeInsets.only(right: 8),
      ),
      iconStyleData: IconStyleData(
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 24,
          color: AppColors.mutedText,
        ),
      ),
      dropdownStyleData: DropdownStyleData(
        maxHeight: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.cardBackground,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow10,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        offset: const Offset(0, -8),
        scrollbarTheme: ScrollbarThemeData(
          radius: const Radius.circular(40),
          thickness: MaterialStateProperty.all(6),
          thumbVisibility: MaterialStateProperty.all(true),
        ),
      ),
      menuItemStyleData: const MenuItemStyleData(
        height: 48,
        padding: EdgeInsets.only(left: 16, right: 16),
      ),
      dropdownSearchData: DropdownSearchData(
        searchController: _searchController,
        searchInnerWidgetHeight: 50,
        searchInnerWidget: Container(
          height: 50,
          padding: const EdgeInsets.only(
            top: 8,
            bottom: 4,
            right: 8,
            left: 8,
          ),
          child: TextFormField(
            expands: true,
            maxLines: null,
            controller: _searchController,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              hintText: t.get(TextConstants.searchBlockHint),
              hintStyle: TextStyle(
                fontSize: 14,
                color: AppColors.mutedText,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.surfaceBorder,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.surfaceBorder,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.accent,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        searchMatchFn: (item, searchValue) {
          return item.value?.toLowerCase().contains(
                    searchValue.toLowerCase(),
                  ) ??
              false;
        },
      ),
      onMenuStateChange: (isOpen) {
        if (isOpen) {
          // Optional: Add haptic feedback
          // HapticFeedback.selectionClick();
        }
      },
    );
  }
}
