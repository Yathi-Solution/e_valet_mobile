import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:niloufer_valet_mobile/bloc/connectivity/connectivity_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/connectivity/connectivity_state.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_home/driver_menu_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_home/driver_menu_event.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_home/driver_menu_state.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:niloufer_valet_mobile/api/driver/my_parked_sessions_api_service.dart';
import 'package:niloufer_valet_mobile/api/operator/operator_dashboard/operator_manual_retrieval_api_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/driver/parked/my_parked_sessions_response.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/manual_retrieval_request.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/custom_app_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/driver/parked_cars/widgets/driver_parked_car_card.dart';
import 'package:niloufer_valet_mobile/services/offline_sync/offline_parking_service.dart';
import 'package:provider/provider.dart';

class MyParkedCarsScreen extends StatefulWidget {
  const MyParkedCarsScreen({super.key});

  @override
  State<MyParkedCarsScreen> createState() => _MyParkedCarsScreenState();
}

class _MyParkedCarsScreenState extends State<MyParkedCarsScreen> {
  late Future<MyParkedSessionsResponse> _parkedCarsFuture;
  MyParkedSessionsResponse? _prefetchedData;
  final TextEditingController _searchController = TextEditingController();
  final _manualRetrievalApi = OperatorManualRetrievalApiService();
  String _searchQuery = '';
  int? _processingCardNumber;
  ConnectivityState? _lastConnectivityState;

  @override
  void initState() {
    super.initState();
    _prefetchedData = _prefetchedFromMenuBloc();
    _parkedCarsFuture = _loadParkedCars();
  }

  MyParkedSessionsResponse? _prefetchedFromMenuBloc() {
    final menuState = context.read<DriverMenuBloc>().state;
    if (menuState is DriverHomeLoaded) {
      return menuState.parkedCarsData;
    }
    return null;
  }

  Future<MyParkedSessionsResponse> _loadParkedCars() {
    return MyParkedSessionsApiService.loadParkedSessionsForDisplay();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final next = _loadParkedCars();
    setState(() {
      _parkedCarsFuture = next;
    });
    await next;
    if (mounted) {
      context.read<DriverMenuBloc>().add(const DriverPendingSessionsRefresh());
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  List<MyParkedSession> _filterSessions(List<MyParkedSession> sessions) {
    final query = _searchQuery.trim();
    if (query.isEmpty) return sessions;
    return sessions
        .where((s) => s.cardNumber.toString().contains(query))
        .toList(growable: false);
  }

  Future<void> _handleManualRequest({
    required int cardNumber,
    required int outletId,
  }) async {
    if (_processingCardNumber != null) return;

    setState(() => _processingCardNumber = cardNumber);

    try {
      final request = ManualRetrievalRequest(cardNumber: cardNumber);
      final response = await _manualRetrievalApi.createManualRetrievalRequest(
        outletId: outletId > 0
            ? outletId.toString()
            : (dotenv.env['OUTLET_ID'] ?? '1'),
        request: request,
      );

      if (mounted) {
        SnackBars.showSuccessSnackBar(context, response.message);
        await _refresh();
      }
    } catch (e) {
      if (mounted) {
        SnackBars.showErrorSnackBar(
          context,
          getDisplayErrorMessage(e),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingCardNumber = null);
      }
    }
  }

  Widget _buildParkedCarsList(
    MyParkedSessionsResponse data,
    AppTranslationsNotifier t, {
    required bool showManualRequest,
  }) {
    final filteredSessions = _filterSessions(data.sessions);
    final totalCount = data.sessions.length;

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          TextComponent(
            labelText: '${t.get(TextConstants.parkedCarTitle)} ($totalCount)',
            color: AppColors.bodyText,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
          const SizedBox(height: 6),
          TextComponent(
            labelText: t.get(TextConstants.driverParkedCarsDescription),
            color: AppColors.mutedText,
            fontSize: 14,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
            decoration: InputDecoration(
              hintText: t.get(TextConstants.searchByCardNumberHint),
              hintStyle: const TextStyle(color: AppColors.mutedText),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.accent,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AppColors.mutedText,
                      ),
                      onPressed: _clearSearch,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.surfaceBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.surfaceBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.accent,
                  width: 2,
                ),
              ),
            ),
          ),
          if (_searchQuery.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            TextComponent(
              labelText: t.get(
                TextConstants.showingResultsFor(_searchQuery.trim()),
              ),
              color: AppColors.mutedText,
              fontSize: 13,
            ),
          ],
          const SizedBox(height: 16),
          if (totalCount == 0)
            TextComponent(
              labelText: t.get(TextConstants.noCarsParked),
              color: AppColors.mutedText,
              fontStyle: FontStyle.italic,
            )
          else if (filteredSessions.isEmpty)
            TextComponent(
              labelText: t.get(TextConstants.noCarsParked),
              color: AppColors.mutedText,
              fontStyle: FontStyle.italic,
            )
          else
            ...filteredSessions.map(
              (session) => DriverParkedCarCard(
                session: session,
                t: t,
                showManualRequest: showManualRequest,
                isProcessing: _processingCardNumber == session.cardNumber,
                onManualRequest: () => _handleManualRequest(
                  cardNumber: session.cardNumber,
                  outletId: data.outletId,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();

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
        child: BlocBuilder<ConnectivityBloc, ConnectivityState>(
          builder: (context, connectivityState) {
            final showManualRequest =
                connectivityState is ConnectivityOnline;

            if (_lastConnectivityState is! ConnectivityOnline &&
                connectivityState is ConnectivityOnline) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!mounted) return;
                await OfflineParkingService.syncPendingData();
                if (!mounted) return;
                await _refresh();
              });
            }
            _lastConnectivityState = connectivityState;

            return FutureBuilder<MyParkedSessionsResponse>(
              future: _parkedCarsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _prefetchedData != null) {
                  return _buildParkedCarsList(
                    _prefetchedData!,
                    t,
                    showManualRequest: showManualRequest,
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  );
                }

                if (snapshot.hasError) {
                  if (_prefetchedData != null) {
                    return _buildParkedCarsList(
                      _prefetchedData!,
                      t,
                      showManualRequest: showManualRequest,
                    );
                  }

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextComponent(
                            labelText: t.get(TextConstants.errorLabel),
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          TextComponent(
                            labelText: getDisplayErrorMessage(snapshot.error),
                            color: AppColors.mutedText,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _refresh,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.headerDark,
                              foregroundColor: AppColors.textOnDark,
                            ),
                            child: TextComponent(
                              labelText: t.get(TextConstants.retryButton),
                              color: AppColors.textOnDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final data = snapshot.data;
                if (data == null) {
                  if (_prefetchedData != null) {
                    return _buildParkedCarsList(
                      _prefetchedData!,
                      t,
                      showManualRequest: showManualRequest,
                    );
                  }
                  return const SizedBox.shrink();
                }

                return _buildParkedCarsList(
                  data,
                  t,
                  showManualRequest: showManualRequest,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
