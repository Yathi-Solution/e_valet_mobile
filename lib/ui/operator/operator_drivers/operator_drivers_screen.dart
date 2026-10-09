import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/bloc/operator/operator_valet/operator_kpis/valet_kpis_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/operator/operator_valet/operator_kpis/valet_kpis_event.dart';
import 'package:niloufer_valet_mobile/bloc/operator/operator_valet/operator_kpis/valet_kpis_state.dart';
import 'package:niloufer_valet_mobile/bloc/operator/operator_valet/operator_valets/valet_list_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/operator/operator_valet/operator_valets/valet_list_event.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_drivers/widgets/valet_kpis_grid.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_drivers/widgets/valet_list_view.dart';

class OperatorDriversScreen extends StatefulWidget {
  final Function(VoidCallback)? onRefreshReady;
  final Function(int)? onNavigateToTab;

  const OperatorDriversScreen({
    super.key,
    this.onRefreshReady,
    this.onNavigateToTab,
  });

  @override
  State<OperatorDriversScreen> createState() => _OperatorDriversScreenState();
}

enum ValetFilter { all, available, onDuty, onBreak }

class _OperatorDriversScreenState extends State<OperatorDriversScreen> {
  late ValetKpisBloc _valetKpisBloc;
  late ValetListBloc _valetListBloc;
  final String _outletId = dotenv.env['OUTLET_ID'] ?? '1';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ValetFilter _selectedFilter = ValetFilter.all;

  @override
  void initState() {
    super.initState();
    _valetKpisBloc = ValetKpisBloc();
    _valetKpisBloc.add(FetchValetKpis(outletId: _outletId));
    _valetListBloc = ValetListBloc();
    _valetListBloc.add(FetchValetList(outletId: _outletId));
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });

    // Provide the refresh method to the parent immediately
    if (widget.onRefreshReady != null) {
      // Call immediately instead of using addPostFrameCallback
      Future.microtask(() {
        widget.onRefreshReady?.call(refresh);
      });
    }
  }

  void refresh() {
    print('OperatorDriversScreen: refresh() called'); // Debug log
    _valetKpisBloc.add(FetchValetKpis(outletId: _outletId));
    _valetListBloc.add(FetchValetList(outletId: _outletId));
    // Reset filter to show all when refreshing
    if (mounted) {
      setState(() {
        _selectedFilter = ValetFilter.all;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _valetKpisBloc.close();
    _valetListBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _valetKpisBloc),
          BlocProvider.value(value: _valetListBloc),
        ],
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              MediaQuery.of(context).size.width * 0.04,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: back button, title + description (left), search (right) — aligned vertically
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: AppColors.black,
                      onPressed: () {
                        widget.onNavigateToTab?.call(0);
                      },
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextComponent(
                            labelText: t.getByKey('valetDashboardTitle',
                                TextConstants.valetDashboardTitle),
                            color: AppColors.black,
                            fontSize: MediaQuery.of(context).size.width *
                                (Platform.isIOS ? 0.026 : 0.03),
                            fontWeight: FontWeight.bold,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          TextComponent(
                            labelText: t.getByKey('valetDashboardDescription',
                                TextConstants.valetDashboardDescription),
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
                      width: MediaQuery.of(context).size.width *
                          (Platform.isIOS ? 0.32 : 0.4),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.trim();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: t.getByKey('searchByNameOrPhone',
                              TextConstants.searchByNameOrPhone),
                          hintStyle: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: MediaQuery.of(context).size.width * 0.02,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.primary,
                            size: MediaQuery.of(context).size.width * 0.02,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: AppColors.mutedText,
                                    size: MediaQuery.of(context).size.width *
                                        0.02,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                    FocusScope.of(context).unfocus();
                                  },
                                )
                              : null,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.02,
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
                ),
                const SizedBox(height: 24),
                BlocBuilder<ValetKpisBloc, ValetKpisState>(
                  builder: (context, state) {
                    final isLoading = state is ValetKpisLoading;
                    final isLoaded = state is ValetKpisLoaded;

                    if (state is ValetKpisError) {
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
                                _valetKpisBloc.add(
                                  FetchValetKpis(outletId: _outletId),
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

                    return ValetKpisGrid(
                      kpis: isLoaded ? state.kpis : null,
                      isLoading: isLoading,
                      selectedFilter: _selectedFilter,
                      onFilterChanged: (filter) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                ValetListView(
                  outletId: _outletId,
                  searchQuery: _searchQuery,
                  statusFilter: _selectedFilter,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
