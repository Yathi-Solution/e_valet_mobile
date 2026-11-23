import 'package:flutter/material.dart';
import 'package:evalet/api/operator/operator_add_driver/operator_add_driver_api_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/operator/operator_add_driver/add_driver_request.dart';
import 'package:evalet/models/operator/operator_add_driver/add_driver_response.dart';
import 'package:evalet/models/operator/operator_add_driver/client_outlet.dart';
import 'package:evalet/services/translations/app_translations_notifier.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/widgets/text.dart';

/// Operator flow to add a Driver by phone number and assign Outlets.
///
/// Rules from the API doc: the add is never retried after it succeeded (a
/// failed delivery only offers "Resend invitation"), and the response is not
/// used as a profile view.
class AddDriverDialog {
  AddDriverDialog._();

  static Future<void> show({
    required BuildContext context,
    required AppTranslationsNotifier t,
    String? defaultOutletId,
    VoidCallback? onDriverAdded,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddDriverDialogBody(
        t: t,
        defaultOutletId: int.tryParse(defaultOutletId ?? ''),
        onDriverAdded: onDriverAdded,
      ),
    );
  }
}

class _AddDriverDialogBody extends StatefulWidget {
  const _AddDriverDialogBody({
    required this.t,
    this.defaultOutletId,
    this.onDriverAdded,
  });

  final AppTranslationsNotifier t;
  final int? defaultOutletId;
  final VoidCallback? onDriverAdded;

  @override
  State<_AddDriverDialogBody> createState() => _AddDriverDialogBodyState();
}

class _AddDriverDialogBodyState extends State<_AddDriverDialogBody> {
  static const _maxOutlets = 500;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final Set<int> _selectedOutletIds = {};

  List<ClientOutlet> _outlets = const [];
  bool _loadingOutlets = true;
  String? _outletsError;

  bool _submitting = false;
  bool _resending = false;
  String? _errorText;

  /// Set once the add succeeded; the form is then replaced by the result.
  AddDriverResponse? _result;
  String? _resendInfo;

  @override
  void initState() {
    super.initState();
    _loadOutlets();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadOutlets() async {
    setState(() {
      _loadingOutlets = true;
      _outletsError = null;
    });
    try {
      final outlets = await OperatorAddDriverApiService.getClientOutlets();
      if (!mounted) return;
      setState(() {
        _outlets = outlets;
        _loadingOutlets = false;
        final def = widget.defaultOutletId;
        if (def != null && outlets.any((o) => o.id == def)) {
          _selectedOutletIds.add(def);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _outletsError = _messageFor(e);
        _loadingOutlets = false;
      });
    }
  }

  String _messageFor(Object e) {
    if (e is ApiException) {
      if (e.statusCode == 429) {
        return widget.t.getByKey(
          'tooManyAttempts',
          'Too many attempts. Please try again later.',
        );
      }
      if (e.statusCode == 403) {
        return widget.t.getByKey(
          'notAllowedToAddDriver',
          'You are not allowed to do this.',
        );
      }
    }
    return getDisplayErrorMessage(e);
  }

  String? _validate() {
    final t = widget.t;
    if (_nameController.text.trim().isEmpty) {
      return t.getByKey('driverNameRequired', 'Please enter the driver name');
    }
    if (_phoneController.text.trim().isEmpty) {
      return t.getByKey('driverPhoneRequired', 'Please enter the phone number');
    }
    final email = _emailController.text.trim();
    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return t.getByKey('driverEmailInvalid', 'Please enter a valid email');
    }
    if (_selectedOutletIds.isEmpty) {
      return t.getByKey(
          'driverOutletRequired', 'Please select at least one outlet');
    }
    if (_selectedOutletIds.length > _maxOutlets) {
      return t.getByKey(
          'driverOutletTooMany', 'You can select up to $_maxOutlets outlets');
    }
    return null;
  }

  Future<void> _submit() async {
    final validation = _validate();
    if (validation != null) {
      setState(() => _errorText = validation);
      return;
    }
    setState(() {
      _errorText = null;
      _submitting = true;
    });
    try {
      final res = await OperatorAddDriverApiService.addDriver(
        AddDriverRequest(
          name: _nameController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          outletIds: _selectedOutletIds.toList()..sort(),
        ),
      );
      if (!mounted) return;
      widget.onDriverAdded?.call();
      setState(() {
        _result = res;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = _messageFor(e);
        _submitting = false;
      });
    }
  }

  Future<void> _resend() async {
    final userId = _result?.userId;
    if (userId == null || _resending) return;
    setState(() {
      _resending = true;
      _resendInfo = null;
    });
    try {
      await OperatorAddDriverApiService.resendInvitation(userId);
      if (!mounted) return;
      setState(() {
        _resending = false;
        _resendInfo = widget.t.getByKey(
          'invitationResent',
          'Invitation sent again. The previous link no longer works.',
        );
        // Resend succeeded: hide the resend action.
        _result = AddDriverResponse(
          outcome: AddDriverOutcome.invited,
          delivered: true,
          userId: userId,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resending = false;
        _resendInfo = _messageFor(e);
      });
    }
  }

  String _resultMessage(AddDriverResponse r) {
    final t = widget.t;
    switch (r.outcome) {
      case AddDriverOutcome.invited:
        return r.delivered == false
            ? t.getByKey(
                'driverAddedNotDelivered',
                'Driver added, but the invitation could not be delivered. '
                    'You can resend it.',
              )
            : t.getByKey('driverInvited', 'Driver added and invitation sent.');
      case AddDriverOutcome.addedExisting:
        return r.delivered == false
            ? t.getByKey(
                'driverAddedNotDeliveredExisting',
                'Driver added, but the notification could not be delivered.',
              )
            : t.getByKey('driverAddedExisting', 'Driver added.');
      case AddDriverOutcome.outletsAdded:
        return t.getByKey('driverOutletsAdded',
            'This driver is already with you. Outlets were added.');
      case AddDriverOutcome.unknown:
        return t.getByKey('driverAdded', 'Driver added.');
    }
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: TextComponent(
          labelText: text,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
          fontSize: 13,
        ),
      );

  Widget _outletPicker() {
    final t = widget.t;
    if (_loadingOutlets) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_outletsError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextComponent(
            labelText: _outletsError!,
            color: AppColors.error,
            fontSize: 12,
            maxLines: 3,
          ),
          TextButton(
            onPressed: _loadOutlets,
            child: TextComponent(labelText: t.getByKey('retry', 'Retry')),
          ),
        ],
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 180),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grey.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final o in _outlets)
              CheckboxListTile(
                dense: true,
                value: _selectedOutletIds.contains(o.id),
                title: Text(o.name),
                onChanged: _submitting
                    ? null
                    : (v) => setState(() {
                          if (v == true) {
                            _selectedOutletIds.add(o.id);
                          } else {
                            _selectedOutletIds.remove(o.id);
                          }
                        }),
              ),
          ],
        ),
      ),
    );
  }

  Widget _form() {
    final t = widget.t;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(t.getByKey('driverName', 'Name')),
        TextField(
          controller: _nameController,
          enabled: !_submitting,
          textCapitalization: TextCapitalization.words,
          decoration: _decoration(t.getByKey('enterDriverName', 'Enter name')),
        ),
        const SizedBox(height: 14),
        _label(t.getByKey('driverPhone', 'Phone number')),
        TextField(
          controller: _phoneController,
          enabled: !_submitting,
          keyboardType: TextInputType.phone,
          decoration:
              _decoration(t.getByKey('enterDriverPhone', 'Enter phone number')),
        ),
        const SizedBox(height: 14),
        _label(t.getByKey('driverEmailOptional', 'Email (optional)')),
        TextField(
          controller: _emailController,
          enabled: !_submitting,
          keyboardType: TextInputType.emailAddress,
          decoration:
              _decoration(t.getByKey('enterDriverEmail', 'Enter email')),
        ),
        const SizedBox(height: 14),
        _label(t.getByKey('driverOutlets', 'Outlets')),
        _outletPicker(),
        if (_errorText != null) ...[
          const SizedBox(height: 12),
          TextComponent(
            labelText: _errorText!,
            color: AppColors.error,
            fontSize: 12,
            maxLines: 4,
          ),
        ],
      ],
    );
  }

  Widget _resultView(AddDriverResponse r) {
    final t = widget.t;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextComponent(
          labelText: _resultMessage(r),
          color: AppColors.black,
          fontSize: 14,
          maxLines: 6,
        ),
        if (_resendInfo != null) ...[
          const SizedBox(height: 12),
          TextComponent(
            labelText: _resendInfo!,
            color: AppColors.mutedText,
            fontSize: 12,
            maxLines: 4,
          ),
        ],
        if (r.canResend) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _resending ? null : _resend,
            icon: _resending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send, size: 18),
            label: TextComponent(
              labelText: t.getByKey('resendInvitation', 'Resend invitation'),
              color: AppColors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final result = _result;
    return Dialog(
      backgroundColor: AppColors.primarySurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth:
              (MediaQuery.of(context).size.width * 0.9).clamp(280.0, 420.0),
          maxHeight:
              (MediaQuery.of(context).size.height * 0.85).clamp(300.0, 640.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextComponent(
                      labelText: t.getByKey('addDriver', 'Add Driver'),
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _submitting ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.black),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: result == null ? _form() : _resultView(result),
              ),
            ),
            if (result == null) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: TextComponent(
                          labelText: t.getByKey('cancel', 'Cancel'),
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            (_submitting || _loadingOutlets) ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : TextComponent(
                                labelText: t.getByKey('submit', 'Submit'),
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _resending ? null : () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                    child: TextComponent(
                      labelText: t.getByKey('done', 'Done'),
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
