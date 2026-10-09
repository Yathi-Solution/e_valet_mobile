import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/operator/operator_valet/operator_valets/valet_list_bloc.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/bloc/operator/operator_valet/operator_valets/valet_list_event.dart';
import 'package:niloufer_valet_mobile/bloc/operator/operator_valet/operator_valets/valet_list_state.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/api/operator/operator_valet/valet_logout_api_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_valet/valet_response.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_drivers/widgets/valet_card.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_drivers/widgets/valet_details_dialog.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_drivers/operator_drivers_screen.dart';

class ValetListView extends StatelessWidget {
  final String outletId;
  final String searchQuery;
  final ValetFilter statusFilter;

  const ValetListView({
    super.key,
    required this.outletId,
    this.searchQuery = '',
    this.statusFilter = ValetFilter.all,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return BlocBuilder<ValetListBloc, ValetListState>(
      builder: (context, state) {
        if (state is ValetListLoading) {
          const mainAxisSpacing = 12.0;
          final width = MediaQuery.sizeOf(context).width;
          // Phones: single column on narrow screens.
          // Tablets: allow two columns when very wide, even on Android.
          final useTwoColumns =
              width >= 360 && (!Platform.isAndroid || width >= 600);
          if (!useTwoColumns) {
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(bottom: mainAxisSpacing),
                child: const ValetCard(isLoading: true),
              ),
            );
          }
          const crossAxisSpacing = 12.0;
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, rowIndex) {
              return Padding(
                padding: EdgeInsets.only(bottom: mainAxisSpacing),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Expanded(child: ValetCard(isLoading: true)),
                      const SizedBox(width: crossAxisSpacing),
                      const Expanded(child: ValetCard(isLoading: true)),
                    ],
                  ),
                ),
              );
            },
          );
        }

        if (state is ValetListError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextComponent(
                  labelText:
                      '${t.get(TextConstants.errorLabel)}: ${state.message}',
                  color: AppColors.error,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<ValetListBloc>().add(
                          FetchValetList(outletId: outletId),
                        );
                  },
                  child: TextComponent(
                    labelText: t.get(TextConstants.retryButton),
                  ),
                ),
              ],
            ),
          );
        }

        if (state is ValetListLoaded) {
          // First, filter by status based on selected KPI card
          List filteredValets = state.response.valets;
          String digitsOnly(String input) =>
              input.replaceAll(RegExp(r'\D'), '');

          // Apply status filter
          switch (statusFilter) {
            case ValetFilter.available:
              filteredValets = filteredValets
                  .where((valet) => valet.status.toLowerCase() == 'available')
                  .toList();
              break;
            case ValetFilter.onDuty:
              filteredValets = filteredValets
                  .where((valet) => valet.status.toLowerCase() == 'on_duty')
                  .toList();
              break;
            case ValetFilter.onBreak:
              filteredValets = filteredValets
                  .where((valet) => valet.status.toLowerCase() == 'on_break')
                  .toList();
              break;
            case ValetFilter.all:
              // Show all valets
              break;
          }

          // Then filter by searchQuery (name, phone, or userId)
          final query = searchQuery.trim().toLowerCase();
          if (query.isNotEmpty) {
            if (RegExp(r'^\d+$').hasMatch(query)) {
              // If query is digits, allow searching by phone without country code.
              filteredValets = filteredValets
                  .where((valet) =>
                      valet.userId.toLowerCase() == query ||
                      digitsOnly(valet.phone).endsWith(query) ||
                      digitsOnly(valet.phone).contains(query))
                  .toList();
            } else {
              filteredValets = filteredValets.where((valet) {
                return valet.name.toLowerCase().contains(query) ||
                    valet.phone.toLowerCase().contains(query) ||
                    valet.userId.toLowerCase().contains(query);
              }).toList();
            }
          }

          if (filteredValets.isEmpty) {
            return Center(
              child: TextComponent(
                labelText: t.get(TextConstants.noValetsFound),
                color: AppColors.mutedText,
              ),
            );
          }

          // Responsive: single column on narrow (e.g. small phones), two columns on wider.
          const crossAxisSpacing = 12.0;
          const mainAxisSpacing = 12.0;
          final width = MediaQuery.sizeOf(context).width;
          // Phones: single column on narrow screens.
          // Tablets: allow two columns when very wide, even on Android.
          final useTwoColumns =
              width >= 360 && (!Platform.isAndroid || width >= 600);

          void onLogoutValet(ValetResponse v) async {
            try {
              await ValetLogoutApiService.logoutValet(userId: v.userId);

              if (context.mounted) {
                context
                    .read<ValetListBloc>()
                    .add(FetchValetList(outletId: outletId));

                final tr = context.read<AppTranslationsNotifier>();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tr.get(TextConstants.logout)),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            } on ApiException catch (e) {
              print('🔴 OPERATOR VALET FORCE LOGOUT ApiException:');
              print('   message: ${e.message}');
              print('   code: ${e.code}');

              if (context.mounted) {
                SnackBars.showErrorSnackBar(context, e.displayMessage);
              }
            } catch (e) {
              print('🔴 OPERATOR VALET FORCE LOGOUT unknown error: $e');

              if (context.mounted) {
                final tr = context.read<AppTranslationsNotifier>();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${tr.get(TextConstants.errorLabel)}: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          }

          if (!useTwoColumns) {
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredValets.length,
              itemBuilder: (context, index) {
                final valet = filteredValets[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: mainAxisSpacing),
                  child: ValetCard(
                    valet: valet,
                    onTap: () => ValetDetailsDialog.show(
                      context,
                      valet,
                      onLogoutValet: onLogoutValet,
                    ),
                    onLogoutValet: onLogoutValet,
                  ),
                );
              },
            );
          }

          // Two columns: cards side by side, row height = taller card
          final rowCount = (filteredValets.length + 1) ~/ 2;
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rowCount,
            itemBuilder: (context, rowIndex) {
              final leftIndex = rowIndex * 2;
              final rightIndex = rowIndex * 2 + 1;
              final leftValet = leftIndex < filteredValets.length
                  ? filteredValets[leftIndex]
                  : null;
              final rightValet = rightIndex < filteredValets.length
                  ? filteredValets[rightIndex]
                  : null;
              return Padding(
                padding: EdgeInsets.only(bottom: mainAxisSpacing),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ValetCard(
                          valet: leftValet,
                          onTap: () => ValetDetailsDialog.show(
                            context,
                            leftValet!,
                            onLogoutValet: onLogoutValet,
                          ),
                          onLogoutValet: onLogoutValet,
                        ),
                      ),
                      const SizedBox(width: crossAxisSpacing),
                      Expanded(
                        child: rightValet != null
                            ? ValetCard(
                                valet: rightValet,
                                onTap: () => ValetDetailsDialog.show(
                                  context,
                                  rightValet!,
                                  onLogoutValet: onLogoutValet,
                                ),
                                onLogoutValet: onLogoutValet,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
