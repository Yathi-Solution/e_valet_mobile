import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/bloc/operator/car_logs/car_logs_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/operator/car_logs/car_logs_event.dart';
import 'package:niloufer_valet_mobile/bloc/operator/car_logs/car_logs_state.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/car_log.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_car_logs/widgets/car_logs_kpi_grid.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_car_logs/widgets/car_logs_table_skeleton.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_car_logs/widgets/car_logs_table_widget.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_car_logs/widgets/table_header_row_widget.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_car_logs/widgets/page_button_widget.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_car_logs/widgets/page_size_dropdown_widget.dart';
import 'package:niloufer_valet_mobile/ui/operator/operator_car_logs/widgets/car_log_details_popup.dart';

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

  int _getTotalPages() {
    return (_totalItems / _itemsPerPage).ceil();
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
      _isTableLoading = true;
    });
    _fetchCarLogs();
  }

  void _goToFirstPage() {
    _goToPage(1);
  }

  void _goToLastPage() {
    _goToPage(_getTotalPages());
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      _goToPage(_currentPage - 1);
    }
  }

  void _goToNextPage() {
    if (_currentPage < _getTotalPages()) {
      _goToPage(_currentPage + 1);
    }
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _carLogsBloc,
      child: Stack(
        children: [
          SafeArea(
            child: BlocBuilder<CarLogsBloc, CarLogsState>(
              builder: (context, state) {
                final t = context.watch<AppTranslationsNotifier>();
                if (state is CarLogsLoading) {
                  return _buildSkeletonLayout(context);
                } else if (state is CarLogsLoaded) {
                  // Update total items from server response
                  _totalItems = state.carLogsResponse.total;
                  _currentPage = state.carLogsResponse.page;
                  _itemsPerPage = state.carLogsResponse.pageSize;
                  _isTableLoading = false; // Reset loading state
                  _isFetchingData = false; // Reset fetching flag

                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      // Dismiss keyboard when tapping anywhere on the screen
                      FocusScope.of(context).unfocus();
                    },
                    child: Padding(
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
                                      labelText:
                                          '${t.get(TextConstants.carLogsTitle)} (${state.carLogsResponse.total})',
                                      color: AppColors.black,
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              (Platform.isIOS ? 0.026 : 0.03),
                                      fontWeight: FontWeight.bold,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    TextComponent(
                                      labelText: t.getByKey(
                                          'carLogsDescription',
                                          TextConstants.carLogsDescription),
                                      color: AppColors.mutedText,
                                      fontSize:
                                          MediaQuery.of(context).size.width *
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
                                  focusNode: _searchFocusNode,
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.search,
                                  onSubmitted: (_) => _runSearch(),
                                  onChanged: (value) {
                                    setState(() => _searchQuery = value.trim());
                                    // Search when user types a space (after a word)
                                    if (value.endsWith(' ')) {
                                      _runSearch();
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: t.getByKey('carLogsSearchHint',
                                        TextConstants.carLogsSearchHint),
                                    hintStyle: TextStyle(
                                      color: AppColors.mutedText,
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.02,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: AppColors.primary,
                                      size: MediaQuery.of(context).size.width *
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
                                              0.02,
                                      vertical:
                                          MediaQuery.of(context).size.height *
                                              0.01,
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
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.02,
                                    color: AppColors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          CarLogsKpiGrid(kpis: state.kpis),
                          const SizedBox(height: 24),
                          if (state.carLogsResponse.logs.isEmpty)
                            Expanded(
                              child: Center(
                                child: TextComponent(
                                  labelText:
                                      t.get(TextConstants.carLogsNoDataMessage),
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
                                              logs: _sortLogs(
                                                  state.carLogsResponse.logs),
                                              sortColumn: _sortColumn,
                                              sortDirection: _sortDirection,
                                              onHeaderTap: _onHeaderTap,
                                              getSortIcon: _getSortIcon,
                                              sortLogs: _sortLogs,
                                              onRowTap: _onRowTap,
                                            ),
                                          ),
                                  ),
                                  _buildPaginationControls(
                                      context, state.carLogsResponse.logs),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                } else if (state is CarLogsError) {
                  _isFetchingData = false; // Reset fetching flag on error
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      // Dismiss keyboard when tapping anywhere on the screen
                      FocusScope.of(context).unfocus();
                    },
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
                            onPressed: () {
                              _carLogsBloc.add(FetchCarLogs(
                                outletId: _outletId,
                                page: _currentPage,
                                pageSize: _itemsPerPage,
                                search:
                                    _searchQuery.isEmpty ? null : _searchQuery,
                              ));
                            },
                            child: TextComponent(
                              labelText: t.get(TextConstants.retryButton),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
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

  List<CarLog> _sortLogs(List<CarLog> logs) {
    if (_sortColumn.isEmpty || _sortDirection == SortDirection.none) {
      return logs;
    }

    final sortedLogs = List<CarLog>.from(logs);

    sortedLogs.sort((a, b) {
      dynamic aValue;
      dynamic bValue;

      switch (_sortColumn) {
        case TextConstants.carLogsTagNumber:
          aValue = a.tagNumber;
          bValue = b.tagNumber;
          break;
        case TextConstants.carLogsCarStatus:
          aValue = a.displayStatus;
          bValue = b.displayStatus;
          break;
        case TextConstants.carLogsDuration:
          aValue = a.duration;
          bValue = b.duration;
          break;
        case TextConstants.carLogsParkLocation:
          aValue = a.parkingLocation;
          bValue = b.parkingLocation;
          break;
        case TextConstants.carLogsParkedAt:
          aValue = DateTime.tryParse(a.parkedAt) ?? DateTime.now();
          bValue = DateTime.tryParse(b.parkedAt) ?? DateTime.now();
          break;
        case TextConstants.carLogsParkedBy:
          aValue = a.parkedBy.name;
          bValue = b.parkedBy.name;
          break;
        case TextConstants.carLogsRequestedMode:
          aValue = a.requestedMode;
          bValue = b.requestedMode;
          break;
        case TextConstants.carLogsRequestedAt:
          aValue = a.requestedAt.isEmpty
              ? null
              : DateTime.tryParse(a.requestedAt) ?? DateTime(0);
          bValue = b.requestedAt.isEmpty
              ? null
              : DateTime.tryParse(b.requestedAt) ?? DateTime(0);
          if (aValue == null && bValue == null) return 0;
          if (aValue == null)
            return _sortDirection == SortDirection.ascending ? 1 : -1;
          if (bValue == null)
            return _sortDirection == SortDirection.ascending ? -1 : 1;
          break;
        case TextConstants.carLogsHandoveredBy:
          aValue = a.handoveredBy.name;
          bValue = b.handoveredBy.name;
          break;
        case TextConstants.carLogsHandoverAt:
          aValue = a.handoveredAt.isEmpty
              ? null
              : DateTime.tryParse(a.handoveredAt) ?? DateTime(0);
          bValue = b.handoveredAt.isEmpty
              ? null
              : DateTime.tryParse(b.handoveredAt) ?? DateTime(0);
          if (aValue == null && bValue == null) return 0;
          if (aValue == null)
            return _sortDirection == SortDirection.ascending ? 1 : -1;
          if (bValue == null)
            return _sortDirection == SortDirection.ascending ? -1 : 1;
          break;
        default:
          return 0;
      }

      int comparison = 0;
      if (aValue is String && bValue is String) {
        comparison = aValue.toLowerCase().compareTo(bValue.toLowerCase());
      } else if (aValue is int && bValue is int) {
        comparison = aValue.compareTo(bValue);
      } else if (aValue is DateTime && bValue is DateTime) {
        comparison = aValue.compareTo(bValue);
      }

      return _sortDirection == SortDirection.ascending
          ? comparison
          : -comparison;
    });

    return sortedLogs;
  }

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

  Widget _buildPaginationControls(BuildContext context, List<CarLog> logs) {
    final t = context.watch<AppTranslationsNotifier>();
    final totalPages = _getTotalPages();
    final pageInfoText =
        '${(_currentPage - 1) * _itemsPerPage + 1}-${_currentPage * _itemsPerPage > _totalItems ? _totalItems : _currentPage * _itemsPerPage} of $_totalItems';

    // Simplified bar when only one page (total from API reflects search)
    if (totalPages <= 1) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PageSizeDropdownWidget(
              itemsPerPage: _itemsPerPage,
              pageSizeOptions: _pageSizeOptions,
              onPageSizeChanged: _changePageSize,
            ),
            const Spacer(),
            Flexible(
              child: TextComponent(
                labelText: pageInfoText,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.mutedText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    final paginationRow = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Page size dropdown
        PageSizeDropdownWidget(
          itemsPerPage: _itemsPerPage,
          pageSizeOptions: _pageSizeOptions,
          onPageSizeChanged: _changePageSize,
        ),
        const SizedBox(width: 8),
        // First page button (<<) - only show if not on first page
        if (_currentPage > 1)
          IconButton(
            icon: TextComponent(
              labelText: t.get(TextConstants.paginationFirst),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            onPressed: _goToFirstPage,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
          ),
        // Previous page button (<) - only show if not on first page
        if (_currentPage > 1)
          IconButton(
            icon: TextComponent(
              labelText: t.get(TextConstants.paginationPrev),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            onPressed: _goToPreviousPage,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
          ),
        if (_currentPage > 1) const SizedBox(width: 8),
        ..._buildPageNumbers(totalPages),
        if (_currentPage < totalPages) const SizedBox(width: 8),
        if (_currentPage < totalPages)
          IconButton(
            icon: TextComponent(
              labelText: t.get(TextConstants.paginationNext),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            onPressed: _goToNextPage,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
          ),
        if (_currentPage < totalPages)
          IconButton(
            icon: TextComponent(
              labelText: t.get(TextConstants.paginationLast),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            onPressed: _goToLastPage,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
          ),
        const SizedBox(width: 8),
        TextComponent(
          labelText: pageInfoText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.mutedText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: paginationRow,
      ),
    );
  }

  List<Widget> _buildPageNumbers(int totalPages) {
    final widgets = <Widget>[];
    const maxVisiblePages = 5;

    if (totalPages <= maxVisiblePages) {
      // Show all pages if total is small
      for (int i = 1; i <= totalPages; i++) {
        widgets.add(PageButtonWidget(
          page: i,
          currentPage: _currentPage,
          onPressed: () => _goToPage(i),
        ));
      }
    } else {
      // Show pages with ellipsis for large totals
      if (_currentPage <= 3) {
        // Current page is near the beginning
        for (int i = 1; i <= 4; i++) {
          widgets.add(PageButtonWidget(
            page: i,
            currentPage: _currentPage,
            onPressed: () => _goToPage(i),
          ));
        }
        widgets.add(const Text('...', style: TextStyle(fontSize: 14)));
        widgets.add(PageButtonWidget(
          page: totalPages,
          currentPage: _currentPage,
          onPressed: () => _goToPage(totalPages),
        ));
      } else if (_currentPage >= totalPages - 2) {
        // Current page is near the end
        widgets.add(PageButtonWidget(
          page: 1,
          currentPage: _currentPage,
          onPressed: () => _goToPage(1),
        ));
        widgets.add(const Text('...', style: TextStyle(fontSize: 14)));
        for (int i = totalPages - 3; i <= totalPages; i++) {
          widgets.add(PageButtonWidget(
            page: i,
            currentPage: _currentPage,
            onPressed: () => _goToPage(i),
          ));
        }
      } else {
        // Current page is in the middle
        widgets.add(PageButtonWidget(
          page: 1,
          currentPage: _currentPage,
          onPressed: () => _goToPage(1),
        ));
        widgets.add(const Text('...', style: TextStyle(fontSize: 14)));
        for (int i = _currentPage - 1; i <= _currentPage + 1; i++) {
          widgets.add(PageButtonWidget(
            page: i,
            currentPage: _currentPage,
            onPressed: () => _goToPage(i),
          ));
        }
        widgets.add(const Text('...', style: TextStyle(fontSize: 14)));
        widgets.add(PageButtonWidget(
          page: totalPages,
          currentPage: _currentPage,
          onPressed: () => _goToPage(totalPages),
        ));
      }
    }

    return widgets;
  }
}
