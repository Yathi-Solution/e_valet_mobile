import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/api/oauth/logout_api_service.dart';
import 'package:niloufer_valet_mobile/models/oauth/profile_response.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/elevated_button.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/oauth/profile/profile_info_row.dart';
import 'package:niloufer_valet_mobile/ui/oauth/profile/reset_password_dialog.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/oauth/login/login.dart';

class ProfileContent extends StatefulWidget {
  final ProfileResponse profile;

  /// Outlet the user is signed in for, when stored after outlet selection.
  final String? loggedInOutletDisplay;

  const ProfileContent({
    super.key,
    required this.profile,
    this.loggedInOutletDisplay,
  });

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  bool _deactivating = false;

  Future<void> _deactivateAccount(BuildContext context) async {
    if (_deactivating) return;
    setState(() => _deactivating = true);

    try {
      await LogoutApiService.logout();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(
            initialSuccessMessage: 'Your account has been deleted',
          ),
        ),
        (route) => false,
      );
    } catch (_) {
      if (!context.mounted) return;
      SnackBars.showErrorSnackBar(context, TextConstants.genericError);
    } finally {
      if (mounted) setState(() => _deactivating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final profile = widget.profile;
    final user = profile.user;

    return SingleChildScrollView(
      padding: EdgeInsets.all(
        MediaQuery.of(context).size.width * 0.02,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(
                    MediaQuery.of(context).size.width * 0.05,
                  ),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.05,
                    vertical: MediaQuery.of(context).size.height * 0.02,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: MediaQuery.of(context).size.width * 0.1,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Icon(
                          Icons.person_outline,
                          size: MediaQuery.of(context).size.width * 0.1,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02,
                      ),
                      TextComponent(
                        labelText: user.fullName.isNotEmpty
                            ? user.fullName
                            : TextConstants.userFallbackName,
                        fontSize: MediaQuery.of(context).size.width * 0.05,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.01,
                      ),
                      if (profile.roles.isNotEmpty)
                        TextComponent(
                          labelText: profile.roles.join(' · '),
                          fontSize: MediaQuery.of(context).size.width * 0.03,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02,
                      ),
                      Divider(
                        color: AppColors.primary,
                        thickness: 1,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.01,
                      ),
                      ProfileInfoRow(
                        icon: Icons.phone_outlined,
                        label: t.get(TextConstants.phoneLabel),
                        value: user.phoneNumber,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.01,
                      ),
                      ProfileInfoRow(
                        icon: Icons.email_outlined,
                        label: t.get(TextConstants.emailLabel),
                        value: user.email,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.01,
                      ),
                      ProfileInfoRow(
                        icon: Icons.badge_outlined,
                        label: t.get(TextConstants.usernameLabel),
                        value: user.username,
                      ),
                      if (widget.loggedInOutletDisplay != null &&
                          widget.loggedInOutletDisplay!.isNotEmpty) ...[
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01,
                        ),
                        ProfileInfoRow(
                          icon: Icons.storefront_outlined,
                          label: t.get(TextConstants.profileOutletLabel),
                          value: widget.loggedInOutletDisplay!,
                        ),
                      ],
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.01,
                      ),
                      ProfileInfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: t.get(TextConstants.joinedLabel),
                        value: user.createdAt.split('T').first,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.03,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButtonComponent(
                          elevatedButtonBackgroundColor: AppColors.primary,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dialogContext) =>
                                  const ResetPasswordDialog(),
                            );
                          },
                          labelText: t.get(TextConstants.resetPassword),
                          fontColor: AppColors.textOnDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ), // ConstrainedBox
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.qrErrorBg,
                  borderRadius: BorderRadius.circular(
                    MediaQuery.of(context).size.width * 0.04,
                  ),
                  border: Border.all(
                    color: AppColors.qrErrorColor.withOpacity(0.45),
                    width: 1,
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                  vertical: MediaQuery.of(context).size.height * 0.02,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextComponent(
                      labelText: 'Danger Zone',
                      fontSize: MediaQuery.of(context).size.width * 0.045,
                      fontWeight: FontWeight.w700,
                      color: AppColors.qrErrorColor,
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.01,
                    ),
                    TextComponent(
                      labelText:
                          'When you click on the Deactivate Account button, your account will be removed from this application.',
                      fontSize: MediaQuery.of(context).size.width * 0.035,
                      fontWeight: FontWeight.w500,
                      color: AppColors.qrErrorColor.withOpacity(0.85),
                      textAlign: TextAlign.start,
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _deactivating
                            ? null
                            : () => _deactivateAccount(context),
                        icon: _deactivating
                            ? SizedBox(
                                width: MediaQuery.of(context).size.width * 0.04,
                                height:
                                    MediaQuery.of(context).size.width * 0.04,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.logout),
                        label: TextComponent(
                          labelText: _deactivating
                              ? 'Deactivating...'
                              : 'Deactivate Account',
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                          fontWeight: FontWeight.w600,
                          color: AppColors.qrErrorColor,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical:
                                MediaQuery.of(context).size.height * 0.015,
                          ),
                          side: BorderSide(
                            color: AppColors.qrErrorColor,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              MediaQuery.of(context).size.width * 0.03,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version =
                    snapshot.hasData ? snapshot.data!.version : null;
                if (version == null || version.isEmpty) {
                  return const SizedBox.shrink();
                }
                return TextComponent(
                  labelText: version,
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                  color: AppColors.mutedText,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
