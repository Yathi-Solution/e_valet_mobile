import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/api/ope_driv_help_support_api/help_support_api.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/custom_app_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/guidelines/guidelines_main_title.dart';
import 'package:niloufer_valet_mobile/ui/guidelines/guidelines_section.dart';
import 'package:niloufer_valet_mobile/ui/help_support/contact_card.dart';

/// Shared Help screen for both Driver and Operator roles.
/// Accessible from the overflow menu (driver) and side drawer (operator).
/// Fetches support members from GET /api/support-members.
/// When [isFromOperator] is true, the title is translated (Hindi/Telugu).
class HelpScreen extends StatefulWidget {
  /// When true, opened from operator drawer - show translated title.
  final bool isFromOperator;

  const HelpScreen({super.key, this.isFromOperator = false});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  List<ContactInfo>? _contacts;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSupportMembers();
  }

  Future<void> _loadSupportMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _contacts = null;
    });

    try {
      final members = await HelpSupportApi.fetchSupportMembers();
      if (mounted) {
        setState(() {
          _contacts = members.map(ContactInfo.fromSupportMember).toList();
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = TextConstants.helpFailedToLoad;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    // Always use backend translation for title (Hindi/Telugu)
    final title = t.getByKey('help', TextConstants.help);
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GuidelinesMainTitle(title: title),
                    const SizedBox(height: 24),
                    GuidelinesSection(
                      title: t.getByKey('helpContactSupport',
                          TextConstants.helpContactSupport),
                      icon: Icons.support_agent,
                      items: const [],
                    ),
                    const SizedBox(height: 12),
                    _buildContactsContent(t),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsContent(AppTranslationsNotifier t) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              TextComponent(
                labelText: t.get(TextConstants.helpLoadingContacts),
                fontSize: 14,
                color: AppColors.mutedText,
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.mutedText),
              const SizedBox(height: 12),
              TextComponent(
                labelText: _errorMessage!,
                fontSize: 14,
                color: AppColors.mutedText,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _loadSupportMembers,
                icon: const Icon(Icons.refresh),
                label:
                    TextComponent(labelText: t.get(TextConstants.retryButton)),
              ),
            ],
          ),
        ),
      );
    }

    final contacts = _contacts ?? [];
    if (contacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: TextComponent(
            labelText: t.get(TextConstants.helpNoContacts),
            fontSize: 14,
            color: AppColors.mutedText,
          ),
        ),
      );
    }

    return Column(
      children: contacts
          .map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ContactCard(contact: c),
            ),
          )
          .toList(),
    );
  }
}
