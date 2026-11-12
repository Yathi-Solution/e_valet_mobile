import 'package:flutter/material.dart';
import 'package:evalet/models/oauth/client_summary.dart';
import 'package:evalet/ui/common/colors.dart';

/// Center dialog for choosing which client to sign in to when the account
/// belongs to more than one. Styled to match [OutletSelectionDialog].
class ClientSelectionDialog extends StatelessWidget {
  final List<ClientSummary> clients;
  final void Function(ClientSummary client) onClientSelected;
  final VoidCallback onCancel;

  const ClientSelectionDialog({
    super.key,
    required this.clients,
    required this.onClientSelected,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: AppColors.primarySurface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 480,
          maxHeight: 520,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.business_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Client',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Choose the client you want to sign in to',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: clients.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    return _ClientTile(
                      client: client,
                      onTap: () => onClientSelected(client),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onCancel,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientTile extends StatelessWidget {
  final ClientSummary client;
  final VoidCallback onTap;

  const _ClientTile({
    required this.client,
    required this.onTap,
  });

  /// "CLIENT_ADMIN" -> "Client Admin".
  String? get _roleLabel {
    final role = client.role?.trim();
    if (role == null || role.isEmpty) return null;
    return role
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final name = client.name.trim();
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    final roleLabel = _roleLabel;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    if (roleLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        roleLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.mutedText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
