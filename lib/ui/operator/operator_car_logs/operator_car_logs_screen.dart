import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:evalet/services/translations/app_translations_notifier.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/widgets/text.dart';
import 'package:evalet/ui/common/text_constants.dart';
import 'package:evalet/bloc/operator/car_logs/car_logs_bloc.dart';
import 'package:evalet/bloc/operator/car_logs/car_logs_event.dart';
import 'package:evalet/bloc/operator/car_logs/car_logs_state.dart';
import 'package:evalet/models/operator/operator_dashboard/car_log.dart';
import 'package:evalet/ui/operator/operator_car_logs/widgets/car_logs_kpi_grid.dart';
import 'package:evalet/ui/operator/operator_car_logs/widgets/car_logs_table_skeleton.dart';
import 'package:evalet/ui/operator/operator_car_logs/widgets/car_logs_table_widget.dart';
import 'package:evalet/ui/operator/operator_car_logs/widgets/table_header_row_widget.dart';
import 'package:evalet/ui/operator/operator_car_logs/car_logs_sorter.dart';
import 'package:evalet/ui/operator/operator_car_logs/widgets/car_logs_header.dart';
import 'package:evalet/ui/operator/operator_car_logs/widgets/car_logs_pagination_bar.dart';
import 'package:evalet/ui/operator/operator_car_logs/widgets/car_log_details_popup.dart';

class OperatorCarLogsScreen extends StatefulWidget {
  final Function(VoidCallback)? onRefreshReady;
  final Function(int)? onNavigateToTab;

  const OperatorCarLogsScreen({
    super.key,
    this.onRefreshReady,
    this.onNavigateToTab,
  });

  @override
  State<OperatorCarLogsScreen> createState() => _OperatorCarLogsScreenState();
}

class _OperatorCarLogsScreenState extends State<OperatorCarLogsScreen> {
  late CarLogsBloc _carLogsBloc;
  final String _outletId = dotenv.env['OUTLET_ID'] ?? '1';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Sorting state
  String _sortColumn = '';
  SortDirection _sortDirection = SortDirection.none;

  // Pagination state
  static const List<int> _pageSizeOptions = [10, 20, 50, 100];
  int _itemsPerPage = 10;
  int _currentPage = 1;
  int _totalItems = 0;

  // Loading state for table
  bool _isTableLoading = false;
  bool _isFetchingData = false; // Prevent multiple simultaneous requests

  // Popup state
  CarLog? _selectedCarLog;
  bool _showPopup = false;

  // Search runs on: Done key, keyboard close, or space after a word
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _carLogsBloc = CarLogsBloc();
    _isTableLoading = true; // Set loading on initial load
    _fetchCarLogs();

    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && mounted) {
        _runSearch();
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
    _carLogsBloc.add(FetchCarLogs(
      outletId: _outletId,
      page: _currentPage,
      pageSize: _itemsPerPage,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    ));
  }

  /// Run search with current query. Called on Done, keyboard close, or space after word.
  void _runSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _currentPage = 1;
      _isTableLoading = true;
    });
    _fetchCarLogs();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    _carLogsBloc.close();
    super.dispose();
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _currentPage = 1; // Reset to first page when search is cleared
      _isTableLoading = true;
    });
    _fetchCarLogs();
  }

  void _fetchCarLogs() {
    if (_isFetchingData) return; // Prevent multiple simultaneous requests

    _isFetchingData = true;
    _carLogsBloc.add(FetchCarLogs(
      outletId: _outletId,
      page: _currentPage,
      pageSize: _itemsPerPage,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    ));
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
      _isTableLoading = true;
    });
    _fetchCarLogs();
  }

  void _changePageSize(int newSize) {
    setState(() {
      _itemsPerPage = newSize;
      _currentPage = 1; // Reset to first page when page size changes
      _isTableLoading = true;
    });
    _fetchCarLogs();
  }

  void _onRowTap(CarLog carLog) {
    // Dismiss keyboard when opening popup
    FocusScope.of(context).unfocus();

    setState(() {
      _selectedCarLog = carLog;
      _showPopup = true;
    });
  }

  void _closePopup() {
    setState(() {
      _showPopup = false;
      _selectedCarLog = null;
    });
  }

  Widget _buildSkeletonLayout(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: back, title placeholder, search placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: AppColors.black,
                  onPressed: () => widget.onNavigateToTab?.call(0),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextComponent(
                      labelText: t.get(TextConstants.carLogsTitle),
                      color: AppColors.black,
                      fontSize: MediaQuery.of(context).size.width * 0.03,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 4),
                    TextComponent(
                      labelText: t.getByKey('carLogsDescription',
                          TextConstants.carLogsDescription),
                      color: AppColors.mutedText,
                      fontSize: MediaQuery.of(context).size.width * 0.02,
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            CarLogsKpiGrid(isLoading: true),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: CarLogsTableSkeleton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _dismissKeyboard() => FocusScope.of(context).unfocus();

  Widget _buildLoaded(BuildContext context, CarLogsLoaded state) {
    final t = context.watch<AppTranslationsNotifier>();
    // Update total items from server response
    _totalItems = state.carLogsResponse.total;
    _currentPage = state.carLogsResponse.page;
    _itemsPerPage = state.carLogsResponse.pageSize;
    _isTableLoading = false; // Reset loading state
    _isFetchingData = false; // Reset fetching flag

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      // Dismiss keyboard when tapping anywhere on the screen
      onTap: _dismissKeyboard,
      child: Padding(
        padding: EdgeInsets.all(
          MediaQuery.of(context).size.width * 0.04,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarLogsHeader(
              total: state.carLogsResponse.total,
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              searchQuery: _searchQuery,
              onBack: () => widget.onNavigateToTab?.call(0),
              onSearch: _runSearch,
              onQueryChanged: (query) => setState(() => _searchQuery = query),
              onClear: _clearSearch,
            ),
            const SizedBox(height: 24),
            CarLogsKpiGrid(kpis: state.kpis),
            const SizedBox(height: 24),
            if (state.carLogsResponse.logs.isEmpty)
              Expanded(
                child: Center(
                  child: TextComponent(
                    labelText: t.get(TextConstants.carLogsNoDataMessage),
                    color: AppColors.mutedText,
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _isTableLoading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : SingleChildScrollView(
                              child: CarLogsTableWidget(
                                logs: _sortLogs(state.carLogsResponse.logs),
                                sortColumn: _sortColumn,
                                sortDirection: _sortDirection,
                                onHeaderTap: _onHeaderTap,
                                getSortIcon: _getSortIcon,
                                sortLogs: _sortLogs,
                                onRowTap: _onRowTap,
                              ),
                            ),
                    ),
                    CarLogsPaginationBar(
                      currentPage: _currentPage,
                      itemsPerPage: _itemsPerPage,
                      totalItems: _totalItems,
                      pageSizeOptions: _pageSizeOptions,
                      onPageSizeChanged: _changePageSize,
                      onGoToPage: _goToPage,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, CarLogsError state) {
    final t = context.watch<AppTranslationsNotifier>();
    _isFetchingData = false; // Reset fetching flag on error
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      // Dismiss keyboard when tapping anywhere on the screen
      onTap: _dismissKeyboard,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextComponent(
              labelText: t.get(TextConstants.carLogsErrorMessage),
              color: AppColors.error,
            ),
            const SizedBox(height: 8),
            TextComponent(
              labelText: state.message,
              color: AppColors.mutedText,
              fontSize: 12,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: refresh,
              child: TextComponent(
                labelText: t.get(TextConstants.retryButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _carLogsBloc,
      child: Stack(
        children: [
          SafeArea(
            child: BlocBuilder<CarLogsBloc, CarLogsState>(
              builder: (context, state) {
                // Rebuild when the language changes.
                context.watch<AppTranslationsNotifier>();
                if (state is CarLogsLoading) {
                  return _buildSkeletonLayout(context);
                } else if (state is CarLogsLoaded) {
                  return _buildLoaded(context, state);
                } else if (state is CarLogsError) {
                  return _buildError(context, state);
                }
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
          ),
          if (_showPopup && _selectedCarLog != null)
            Positioned.fill(
              child: CarLogDetailsPopup(
                carLog: _selectedCarLog!,
                onClose: _closePopup,
              ),
            ),
        ],
      ),
    );
  }

  /// When user searches by card number (numeric), show only logs that exactly
  /// match that card number. Otherwise show all results from the API.
  List<CarLog> _filterLogsForExactSearch(List<CarLog> logs) {
    final query = _searchQuery.trim();
    if (query.isEmpty) return logs;

    // If search looks like a card number (digits only), show only exact matches
    final isCardNumberSearch = int.tryParse(query) != null;
    if (!isCardNumberSearch) return logs;

    return logs.where((log) => log.tagNumber.toString() == query).toList();
  }

  List<CarLog> _sortLogs(List<CarLog> logs) =>
      sortCarLogs(logs, _sortColumn, _sortDirection);

  void _onHeaderTap(String columnName) {
    setState(() {
      if (_sortColumn == columnName) {
        // Cycle through sort directions: none -> ascending -> descending -> none
        switch (_sortDirection) {
          case SortDirection.none:
            _sortDirection = SortDirection.ascending;
            break;
          case SortDirection.ascending:
            _sortDirection = SortDirection.descending;
            break;
          case SortDirection.descending:
            _sortDirection = SortDirection.none;
            _sortColumn = '';
            break;
        }
      } else {
        _sortColumn = columnName;
        _sortDirection = SortDirection.ascending;
      }
    });
  }

  IconData? _getSortIcon(String columnName) {
    if (_sortColumn != columnName) return null;

    switch (_sortDirection) {
      case SortDirection.ascending:
        return Icons.arrow_upward;
      case SortDirection.descending:
        return Icons.arrow_downward;
      case SortDirection.none:
        return null;
    }
  }
}
