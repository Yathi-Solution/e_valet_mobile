import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/models/help_support/support_member.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';

/// Contact info for display in ContactCard.
/// [team] is optional; when null, displays [TextConstants.helpSupportTeam].
class ContactInfo {
  final String name;
  final String? team;
  final String phone;

  const ContactInfo({
    required this.name,
    this.team,
    required this.phone,
  });

  /// Creates ContactInfo from [SupportMember] (API response).
  factory ContactInfo.fromSupportMember(SupportMember member) {
    final phone = member.phoneNumber.trim();
    final displayPhone =
        phone.startsWith('+') ? phone : '${TextConstants.countryCode}-$phone';
    return ContactInfo(
      name: member.name,
      team: null,
      phone: displayPhone,
    );
  }
}

class ContactCard extends StatelessWidget {
  final ContactInfo contact;

  const ContactCard({super.key, required this.contact});

  String _phoneDigitsOnly(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }

  /// Strips leading country code `91` for local dialing when the number is stored
  /// as `+91` + 10 digits (typical Indian mobile/support lines from the API).
  String _digitsForDial(String digitsOnly) {
    if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
      return digitsOnly.substring(2);
    }
    return digitsOnly;
  }

  Future<void> _makeCall() async {
    final digits = _digitsForDial(_phoneDigitsOnly(contact.phone));
    if (digits.isNotEmpty) {
      await FlutterPhoneDirectCaller.callNumber(digits);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primarySoft,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow10,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person,
              size: 26,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextComponent(
                  labelText: contact.name,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                const SizedBox(height: 2),
                TextComponent(
                  labelText:
                      contact.team ?? t.get(TextConstants.helpSupportTeam),
                  fontSize: 13,
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w500,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 14,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    TextComponent(
                      labelText: contact.phone,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _makeCall,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.phone,
                color: AppColors.secondary,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
