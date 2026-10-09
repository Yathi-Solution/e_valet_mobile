import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/bloc/operator/operator_dashboard/operator_dashboard_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/operator/operator_dashboard/operator_dashboard_event.dart';
import 'package:niloufer_valet_mobile/bloc/operator/operator_dashboard/operator_dashboard_state.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/elevated_button.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';

class ManualRequestWidget extends StatefulWidget {
  final VoidCallback onRequestCreated;

  /// Auto mode state (kept for compatibility; does not disable manual request).
  final bool isAutoMode;

  const ManualRequestWidget({
    super.key,
    required this.onRequestCreated,
    this.isAutoMode = false,
  });

  @override
  State<ManualRequestWidget> createState() => _ManualRequestWidgetState();
}

class _ManualRequestWidgetState extends State<ManualRequestWidget> {
  final TextEditingController _cardNumberController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    super.dispose();
  }

  void _handleManualRequest() {
    final t = context.read<AppTranslationsNotifier>();
    final cardNumberText = _cardNumberController.text.trim();
    if (cardNumberText.isEmpty) {
      SnackBars.showErrorSnackBar(
          context, t.get(TextConstants.pleaseEnterCardNumber));
      return;
    }

    final cardNumber = int.tryParse(cardNumberText);
    if (cardNumber == null) {
      SnackBars.showErrorSnackBar(
          context, t.get(TextConstants.pleaseEnterValidCardNumber));
      return;
    }

    context.read<OperatorDashboardBloc>().add(
          CreateManualRetrievalRequest(
            cardNumber: cardNumber,
            outletId: dotenv.env['OUTLET_ID'] ?? '1',
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OperatorDashboardBloc, OperatorDashboardState>(
      listener: (context, state) {
        if (state is ManualRequestSuccess) {
          SnackBars.showSuccessSnackBar(context, state.message);
          _cardNumberController.clear();
          // Trigger soft refresh to update the UI
          widget.onRequestCreated();
        } else if (state is ManualRequestError) {
          SnackBars.showErrorSnackBar(context, state.message);
        }
      },
      child: BlocBuilder<OperatorDashboardBloc, OperatorDashboardState>(
        builder: (context, state) {
          final t = context.watch<AppTranslationsNotifier>();
          final isLoading = state is ManualRequestInProgress;

          final isDisabled = isLoading;

          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: MediaQuery.of(context).size.height * 0.02,
              horizontal: MediaQuery.of(context).size.width * 0.01,
            ),
            child: Row(
              children: [
                // Rounded text field with card icon
                Expanded(
                  child: TextFormField(
                    controller: _cardNumberController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    enabled: !isDisabled,
                    decoration: InputDecoration(
                      hintText: t.getByKey(
                          'tagNumberHint', TextConstants.tagNumberHint),
                      hintStyle: const TextStyle(
                        color: AppColors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: AppColors.manualRequestFillColor,
                      prefixIcon: const Icon(
                        Icons.credit_card,
                        color: AppColors.black,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.black,
                    ),
                    onFieldSubmitted:
                        isDisabled ? null : (_) => _handleManualRequest(),
                  ),
                ),

                const SizedBox(width: 16),

                // Manual Request button
                ElevatedButtonComponent(
                  onPressed: isDisabled ? () {} : _handleManualRequest,
                  labelText: isLoading
                      ? t.get(TextConstants.processingText)
                      : t.get(TextConstants.manualRequest),
                  fontColor: AppColors.textOnDark,
                  fontSize: MediaQuery.of(context).size.width * 0.015,
                  elevatedButtonBackgroundColor:
                      isDisabled ? AppColors.grey : AppColors.primary,
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.03,
                    vertical: MediaQuery.of(context).size.height * 0.015,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
