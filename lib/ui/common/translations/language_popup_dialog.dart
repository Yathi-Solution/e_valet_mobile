import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/models/translations/language.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';

/// Popup dialog for language selection. Does not close on tap outside;
/// user must select a language or tap Close.
class LanguagePopupDialog extends StatefulWidget {
  const LanguagePopupDialog({
    super.key,
    required this.languages,
    required this.selectedLanguage,
    required this.onLanguageSelected,
    required this.onClose,
  });

  final List<Language> languages;
  final Language? selectedLanguage;
  final Future<void> Function(Language lang) onLanguageSelected;
  final VoidCallback onClose;

  @override
  State<LanguagePopupDialog> createState() => _LanguagePopupDialogState();
}

class _LanguagePopupDialogState extends State<LanguagePopupDialog> {
  bool _selectionInProgress = false;

  Future<void> _handleLanguageTap(Language lang) async {
    if (_selectionInProgress) return;
    setState(() => _selectionInProgress = true);
    try {
      await widget.onLanguageSelected(lang);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _selectionInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 360,
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow10.withOpacity(0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient accent
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.language_rounded,
                      color: AppColors.primaryDark,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextComponent(
                    labelText: t.get(TextConstants.language),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                  const Spacer(),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _selectionInProgress ? null : widget.onClose,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          _selectionInProgress
                              ? Icons.hourglass_top_rounded
                              : Icons.close_rounded,
                          color: AppColors.mutedText,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Language list
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: widget.languages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final lang = widget.languages[index];
                  final isSelected = widget.selectedLanguage == lang;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _selectionInProgress
                          ? null
                          : () => _handleLanguageTap(lang),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accentSoft
                              : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accent.withOpacity(0.5)
                                : AppColors.surfaceBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextComponent(
                                labelText: lang.nativeName,
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: AppColors.black,
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.accentSoft,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.accent,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
