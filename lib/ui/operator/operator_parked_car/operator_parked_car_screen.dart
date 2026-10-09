import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:niloufer_valet_mobile/api/operator/operator_dashboard/operator_manual_retrieval_api_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/bloc/operator/operator_dashboard/operator_dashboard_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/operator/operator_dashboard/operator_dashboard_event.dart';
import 'package:niloufer_valet_mobile/bloc/operator/operator_dashboard/operator_dashboard_state.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/manual_retrieval_request.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/skeleton_loader.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_parked_car/widgets/parked_car_content_view.dart';

class OperatorParkedCarScreen extends StatefulWidget {
  final Function(VoidCallback)? onRefreshReady;
  final Function(int)? onNavigateToTab;

  /// When true (auto mode enabled), manual request button is disabled.
  final bool isAutoMode;

  const OperatorParkedCarScreen({
    super.key,
    this.onRefreshReady,
    this.onNavigateToTab,
    this.isAutoMode = false,
  });

  @override
  State<OperatorParkedCarScreen> createState() =>
      _OperatorParkedCarScreenState();
}

class _OperatorParkedCarScreenState extends State<OperatorParkedCarScreen> {
  final _apiService = OperatorManualRetrievalApiService();
  final String _outletId = dotenv.env['OUTLET_ID'] ?? '1';
  bool _isProcessing = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    // Fetch the latest data when the screen is first loaded
    // This ensures we get fresh data when navigating from KPI cards or switching tabs
    Future.microtask(() {
      if (mounted) {
        context.read<OperatorDashboardBloc>().add(
              FetchDashboardKpis(outletId: _outletId),
            );
      }
    });

    // Provide the refresh method to the parent
    if (widget.onRefreshReady != null) {
      Future.microtask(() {
        widget.onRefreshReady?.call(refresh);
      });
    }
  }

  void refresh() {
    print('OperatorSlotsScreen: refresh() called'); // Debug log
    // Refresh the dashboard data which includes the slots
    context.read<OperatorDashboardBloc>().add(
          FetchDashboardKpis(outletId: _outletId),
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  Future<void> _handleManualRequest(int cardNumber, String sessionId) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final request = ManualRetrievalRequest(cardNumber: cardNumber);
      final response = await _apiService.createManualRetrievalRequest(
        outletId: _outletId,
        request: request,
      );

      if (mounted) {
        SnackBars.showSuccessSnackBar(
          context,
          response.message,
        );
        // Refresh the data to update UI
        context.read<OperatorDashboardBloc>().add(
              FetchDashboardKpis(outletId: _outletId),
            );
      }
    } catch (e) {
      if (mounted) {
        SnackBars.showErrorSnackBar(
          context,
          'Failed to create manual retrieval request: ${getDisplayErrorMessage(e)}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return SafeArea(
      child: Stack(
        children: [
          BlocBuilder<OperatorDashboardBloc, OperatorDashboardState>(
            builder: (context, state) {
              if (state is OperatorDashboardLoading) {
                return _buildLoadingState(context);
              }

              if (state is OperatorDashboardLoaded) {
                return GestureDetector(
                  onTap: () {
                    // Dismiss keyboard when tapping outside
                    FocusScope.of(context).unfocus();
                  },
                  behavior: HitTestBehavior.translucent,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                      MediaQuery.of(context).size.width * 0.02,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with back button, title, search, and description
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  color: AppColors.black,
                                  onPressed: () {
                                    // Navigate back to dashboard (index 0)
                                    widget.onNavigateToTab?.call(0);
                                  },
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextComponent(
                                      labelText:
                                          '${t.get(TextConstants.parkedCarTitle)} (${state.digitalKeyRack.keyRack.length})',
                                      color: AppColors.black,
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.03,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    const SizedBox(height: 4),
                                    TextComponent(
                                      labelText: t.getByKey(
                                          'parkedCarDescription',
                                          TextConstants.parkedCarDescription),
                                      color: AppColors.mutedText,
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.02,
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.4,
                                  child: TextField(
                                    controller: _searchController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _searchQuery = value;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText: t.getByKey(
                                          'searchByCardNumberHint',
                                          TextConstants.searchByCardNumberHint),
                                      hintStyle: TextStyle(
                                        color: AppColors.mutedText,
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.02,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: AppColors.primary,
                                        size:
                                            MediaQuery.of(context).size.width *
                                                0.02,
                                      ),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(
                                                Icons.clear,
                                                color: AppColors.mutedText,
                                                size: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.02,
                                              ),
                                              onPressed: _clearSearch,
                                            )
                                          : null,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal:
                                            MediaQuery.of(context).size.width *
                                                0.01,
                                        vertical:
                                            MediaQuery.of(context).size.height *
                                                0.01,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color:
                                              AppColors.grey.withOpacity(0.3),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color:
                                              AppColors.grey.withOpacity(0.3),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: AppColors.primary,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.02,
                                      color: AppColors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ParkedCarContentView(
                          digitalKeyRack: state.digitalKeyRack,
                          searchQuery: _searchQuery,
                          onManualRequest: _handleManualRequest,
                          manualRequestEnabled: true,
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is OperatorDashboardError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: MediaQuery.of(context).size.width * 0.08,
                        color: AppColors.error,
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      TextComponent(
                        labelText: t.get(TextConstants.failedToLoadSlotsData),
                        fontSize: MediaQuery.of(context).size.width * 0.02,
                        color: AppColors.error,
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01),
                      TextComponent(
                        labelText: state.message,
                        fontSize: MediaQuery.of(context).size.width * 0.016,
                        color: AppColors.mutedText,
                      ),
                    ],
                  ),
                );
              }

              return _buildLoadingState(context);
            },
          ),
          // Loading overlay when processing manual request
          if (_isProcessing)
            Container(
              color: AppColors.black.withOpacity(0.5),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextComponent(
                          labelText: t.get(
                              TextConstants.creatingManualRetrievalRequest),
                          fontSize: 14,
                          color: AppColors.black,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back icon button to navigate to dashboard
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                color: AppColors.black,
                onPressed: () {
                  // Navigate back to dashboard (index 0)
                  widget.onNavigateToTab?.call(0);
                },
              ),
            ],
          ),
          SkeletonLoader(
            height: MediaQuery.of(context).size.height * 0.03,
            width: MediaQuery.of(context).size.width * 0.3,
            borderRadius: 4,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
          SkeletonLoader(
            height: MediaQuery.of(context).size.height * 0.02,
            width: MediaQuery.of(context).size.width * 0.5,
            borderRadius: 4,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
          Row(
            children: [
              Expanded(
                child: SkeletonLoader(
                  height: MediaQuery.of(context).size.height * 0.1,
                  width: double.infinity,
                  borderRadius: 12,
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.015),
              Expanded(
                child: SkeletonLoader(
                  height: MediaQuery.of(context).size.height * 0.1,
                  width: double.infinity,
                  borderRadius: 12,
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.015),
              Expanded(
                child: SkeletonLoader(
                  height: MediaQuery.of(context).size.height * 0.1,
                  width: double.infinity,
                  borderRadius: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
