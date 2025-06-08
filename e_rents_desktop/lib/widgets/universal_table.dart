import 'package:flutter/material.dart';
import 'custom_search_bar.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// UNIVERSAL TABLE SYSTEM - Complete table solution in one place
// ═══════════════════════════════════════════════════════════════════════════════
//
// This file provides everything needed for data tables:
// - Query parameters and pagination
// - Column configuration and filtering
// - Data providers and table widgets
// - Helper utilities for common cell types
// - Factory methods for quick table creation
//
// Usage Examples:
// 1. Simple table: UniversalTable.create(...)
// 2. Custom provider: extend BaseTableProvider
// 3. Full configuration: UniversalTableWidget with UniversalTableConfig
//
// ═══════════════════════════════════════════════════════════════════════════════

/// Query parameters for server-side data fetching
class TableQuery {
  final int page;
  final int pageSize;
  final String? searchTerm;
  final Map<String, dynamic> filters;
  final String? sortBy;
  final bool sortDescending;

  const TableQuery({
    required this.page,
    required this.pageSize,
    this.searchTerm,
    this.filters = const {},
    this.sortBy,
    this.sortDescending = false,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page + 1, // Backend expects 1-based indexing
      'pageSize': pageSize,
    };

    if (searchTerm?.isNotEmpty == true) {
      params['search'] = searchTerm;
    }

    if (sortBy?.isNotEmpty == true) {
      params['sortBy'] = sortBy;
      params['sortDesc'] = sortDescending;
    }

    // Add filter parameters
    filters.forEach((key, value) {
      if (value != null) {
        params[key] = value;
      }
    });

    return params;
  }

  TableQuery copyWith({
    int? page,
    int? pageSize,
    String? searchTerm,
    Map<String, dynamic>? filters,
    String? sortBy,
    bool? sortDescending,
  }) {
    return TableQuery(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      searchTerm: searchTerm ?? this.searchTerm,
      filters: filters ?? this.filters,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }
}

/// Server response containing paginated data
class PagedResult<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  const PagedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  bool get hasNextPage => page < totalPages - 1;
  bool get hasPreviousPage => page > 0;
}

/// Filter types for table columns
enum FilterType { dropdown, dateRange, checkbox, multiSelect, text }

/// Filter option for dropdowns and multi-select
class FilterOption {
  final String label;
  final dynamic value;

  const FilterOption({required this.label, required this.value});
}

/// Filter configuration for table columns
class TableFilter {
  final String key;
  final String label;
  final FilterType type;
  final List<FilterOption>? options;
  final dynamic defaultValue;

  const TableFilter({
    required this.key,
    required this.label,
    required this.type,
    this.options,
    this.defaultValue,
  });
}

/// Column configuration for tables
class TableColumnConfig<T> {
  final String key;
  final String label;
  final bool sortable;
  final bool filterable;
  final TableColumnWidth width;
  final Widget Function(T item) cellBuilder;
  final TableFilter? filter;

  const TableColumnConfig({
    required this.key,
    required this.label,
    required this.cellBuilder,
    this.sortable = true,
    this.filterable = false,
    this.width = const FlexColumnWidth(1),
    this.filter,
  });
}

/// Data provider interface for table data fetching
abstract class BaseTableProvider<T> {
  Future<PagedResult<T>> fetchData(TableQuery query);
  List<TableColumnConfig<T>> get columns;
  List<TableFilter> get availableFilters;
  String get emptyStateMessage;
}

/// Universal Table Configuration - Define once, use everywhere
class UniversalTableConfig<TModel> {
  final String title;
  final String searchHint;
  final String emptyStateMessage;
  final Map<String, String> columnLabels;
  final Map<String, Widget Function(TModel)> customCellBuilders;
  final Map<String, TableColumnWidth> columnWidths;
  final List<String> hiddenColumns;
  final List<TableFilter> customFilters;
  final Widget? headerActions;
  final void Function(TModel)? onRowTap;
  final void Function(TModel)? onRowDoubleTap;

  const UniversalTableConfig({
    this.title = '',
    this.searchHint = 'Search...',
    this.emptyStateMessage = 'No data available',
    this.columnLabels = const {},
    this.customCellBuilders = const {},
    this.columnWidths = const {},
    this.hiddenColumns = const [],
    this.customFilters = const [],
    this.headerActions,
    this.onRowTap,
    this.onRowDoubleTap,
  });
}

/// Base class for Universal Table Providers - 90% automatic functionality
abstract class BaseUniversalTableProvider<TModel>
    extends BaseTableProvider<TModel> {
  final Future<PagedResult<TModel>> Function(Map<String, dynamic>)
  fetchDataFunction;
  final UniversalTableConfig<TModel> config;

  BaseUniversalTableProvider({
    required this.fetchDataFunction,
    required this.config,
  });

  @override
  String get emptyStateMessage => config.emptyStateMessage;

  @override
  Future<PagedResult<TModel>> fetchData(TableQuery query) async {
    final params = _buildSearchParams(query);
    return await fetchDataFunction(params);
  }

  /// ✅ AUTOMATIC: Build search parameters from table query (mirrors backend Universal System)
  Map<String, dynamic> _buildSearchParams(TableQuery query) {
    final params = <String, dynamic>{
      'page': query.page + 1, // Backend expects 1-based
      'pageSize': query.pageSize,
    };

    // Add search term
    if (query.searchTerm?.isNotEmpty == true) {
      params['searchTerm'] = query.searchTerm;
    }

    // Add sorting
    if (query.sortBy?.isNotEmpty == true) {
      params['sortBy'] = query.sortBy;
      params['sortDesc'] = query.sortDescending;
    }

    // Add filters
    query.filters.forEach((key, value) {
      if (value != null) {
        params[key] = value;
      }
    });

    return params;
  }

  /// ✅ HELPERS: Create standard cells and columns

  /// Helper: Create standard column
  TableColumnConfig<TModel> createColumn({
    required String key,
    required String label,
    required Widget Function(TModel) cellBuilder,
    bool sortable = true,
    TableColumnWidth? width,
  }) {
    return TableColumnConfig<TModel>(
      key: key,
      label: config.columnLabels[key] ?? label,
      cellBuilder: config.customCellBuilders[key] ?? cellBuilder,
      sortable: sortable,
      width: config.columnWidths[key] ?? width ?? const FlexColumnWidth(1),
    );
  }

  /// Helper: Create standard filter
  TableFilter createFilter({
    required String key,
    required String label,
    required FilterType type,
    List<FilterOption>? options,
  }) {
    return TableFilter(key: key, label: label, type: type, options: options);
  }

  /// Helper: Create standard text cell
  Widget textCell(String text, {TextStyle? style}) {
    return Text(
      text,
      style: style ?? const TextStyle(fontSize: 14),
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Helper: Create status badge cell
  Widget statusCell(String status, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (color ?? Colors.blue).withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color ?? Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Helper: Create currency cell
  Widget currencyCell(double amount, {String currency = 'BAM'}) {
    return textCell(
      '${amount.toStringAsFixed(2)} $currency',
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  }

  /// Helper: Create date cell
  Widget dateCell(DateTime? date) {
    if (date == null) return textCell('N/A');
    return textCell(date.toLocal().toString().split(' ')[0]);
  }

  /// Helper: Create action buttons cell
  Widget actionCell(List<Widget> actions) {
    return Row(mainAxisSize: MainAxisSize.min, children: actions);
  }

  /// Helper: Create priority badge cell
  Widget priorityCell(String priority, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color ?? Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          priority,
          style: const TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Helper: Create clickable link cell with icon
  Widget linkCell({
    required String text,
    required VoidCallback onTap,
    IconData? icon,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, size: 18, color: Colors.grey[600]),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: color ?? Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper: Create icon action button cell
  Widget iconActionCell({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    Color? color,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      constraints: const BoxConstraints(),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      color: color,
      onPressed: onPressed,
    );
  }
}

/// Main Universal Table Widget - Complete table solution
class UniversalTableWidget<T> extends StatefulWidget {
  final BaseTableProvider<T> dataProvider;
  final String title;
  final int defaultPageSize;
  final Widget? headerActions;
  final void Function(T)? onRowTap;
  final void Function(T)? onRowDoubleTap;
  final bool showSearch;
  final bool showFilters;
  final bool showColumnVisibility;
  final String searchHint;

  const UniversalTableWidget({
    super.key,
    required this.dataProvider,
    this.title = '',
    this.defaultPageSize = 25,
    this.headerActions,
    this.onRowTap,
    this.onRowDoubleTap,
    this.showSearch = true,
    this.showFilters = true,
    this.showColumnVisibility = true,
    this.searchHint = 'Search...',
  });

  @override
  State<UniversalTableWidget<T>> createState() =>
      _UniversalTableWidgetState<T>();
}

class _UniversalTableWidgetState<T> extends State<UniversalTableWidget<T>> {
  late TableQuery _currentQuery;
  PagedResult<T>? _currentData;
  bool _isLoading = false;
  String? _error;
  T? _selectedItem;

  // UI state
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _columnVisibility = {};
  final Map<String, dynamic> _activeFilters = {};

  @override
  void initState() {
    super.initState();
    _currentQuery = TableQuery(page: 0, pageSize: widget.defaultPageSize);

    // Initialize column visibility
    for (final column in widget.dataProvider.columns) {
      _columnVisibility[column.key] = true;
    }

    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await widget.dataProvider.fetchData(_currentQuery);
      setState(() {
        _currentData = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _updateQuery(TableQuery newQuery) {
    setState(() {
      _currentQuery = newQuery;
    });
    _fetchData();
  }

  void _onSearchChanged(String value) {
    _updateQuery(
      _currentQuery.copyWith(
        searchTerm: value.isEmpty ? null : value,
        page: 0, // Reset to first page
      ),
    );
  }

  void _onPageChanged(int page) {
    _updateQuery(_currentQuery.copyWith(page: page));
  }

  void _onPageSizeChanged(int pageSize) {
    _updateQuery(
      _currentQuery.copyWith(
        pageSize: pageSize,
        page: 0, // Reset to first page
      ),
    );
  }

  void _onFilterChanged(String key, dynamic value) {
    final newFilters = Map<String, dynamic>.from(_activeFilters);
    if (value == null) {
      newFilters.remove(key);
    } else {
      newFilters[key] = value;
    }

    setState(() {
      _activeFilters.clear();
      _activeFilters.addAll(newFilters);
    });

    _updateQuery(
      _currentQuery.copyWith(
        filters: newFilters,
        page: 0, // Reset to first page
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (widget.title.isNotEmpty || widget.headerActions != null)
            _buildHeader(),

          // Search and Filters
          if (widget.showSearch || widget.showFilters) _buildSearchAndFilters(),

          // Table Content
          Expanded(child: _buildTableContent()),

          // Pagination
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // Only show header if there's a title or actions
    if (widget.title.isEmpty && widget.headerActions == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (widget.title.isNotEmpty) ...[
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
          ] else if (widget.headerActions != null) ...[
            const Spacer(), // Push actions to the right when no title
          ],
          if (widget.headerActions != null) widget.headerActions!,
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          // Search bar and column visibility in one row
          Row(
            children: [
              if (widget.showSearch) ...[
                Expanded(
                  child: CustomSearchBar(
                    controller: _searchController,
                    hintText: widget.searchHint,
                    onChanged: _onSearchChanged,
                    onFilterPressed:
                        widget.showFilters ? () => _showFiltersDialog() : null,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (widget.showColumnVisibility) _buildColumnVisibilityButton(),
            ],
          ),
          // Active filters chips on second row if any
          if (widget.showFilters && _activeFilters.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: [_buildActiveFiltersChips()]),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveFiltersChips() {
    return Wrap(
      spacing: 8,
      children:
          _activeFilters.entries.map((entry) {
            final filter = widget.dataProvider.availableFilters.firstWhere(
              (f) => f.key == entry.key,
            );
            return Chip(
              label: Text('${filter.label}: ${entry.value}'),
              onDeleted: () => _onFilterChanged(entry.key, null),
              deleteIcon: const Icon(Icons.close, size: 16),
            );
          }).toList(),
    );
  }

  Widget _buildColumnVisibilityButton() {
    return MenuAnchor(
      builder: (context, controller, child) {
        return SizedBox(
          width: 48,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.view_column, size: 18),
              tooltip: 'Show/Hide Columns',
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
            ),
          ),
        );
      },
      menuChildren: [
        SizedBox(
          width: 250,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'Show Columns',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const Divider(height: 1),
              ...widget.dataProvider.columns.map((column) {
                final isVisible = _columnVisibility[column.key] ?? true;
                return CheckboxListTile(
                  title: Text(column.label),
                  value: isVisible,
                  dense: true,
                  onChanged: (bool? value) {
                    if (value != null) {
                      setState(() {
                        _columnVisibility[column.key] = value;
                      });
                    }
                  },
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableContent() {
    if (_isLoading && (_currentData?.isEmpty ?? true)) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchData, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_currentData?.isEmpty ?? true) {
      return Center(child: Text(widget.dataProvider.emptyStateMessage));
    }

    return _buildTable();
  }

  Widget _buildTable() {
    final visibleColumns =
        widget.dataProvider.columns
            .where((col) => _columnVisibility[col.key] == true)
            .toList();

    return Column(
      children: [
        _buildTableHeader(visibleColumns),
        Expanded(
          child: Stack(
            children: [
              _buildTableBody(visibleColumns),
              // Show subtle loading overlay during sorting/filtering
              if (_isLoading && _currentData?.isNotEmpty == true)
                Container(
                  color: Colors.white.withOpacity(0.7),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Updating table...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(List<TableColumnConfig<T>> visibleColumns) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children:
            visibleColumns.map((column) {
              final isCurrentSort = _currentQuery.sortBy == column.key;
              final isDescending = _currentQuery.sortDescending;

              return Expanded(
                flex: _getColumnFlex(column.width),
                child: InkWell(
                  onTap:
                      column.sortable
                          ? () {
                            String? newSortBy;
                            bool newDescending;

                            if (!isCurrentSort) {
                              // First click on this column - start with ascending
                              newSortBy = column.key;
                              newDescending = false;
                            } else if (!isDescending) {
                              // Currently ascending - switch to descending
                              newSortBy = column.key;
                              newDescending = true;
                            } else {
                              // Currently descending - clear sorting
                              newSortBy = null;
                              newDescending = false;
                            }

                            _updateQuery(
                              _currentQuery.copyWith(
                                sortBy: newSortBy,
                                sortDescending: newDescending,
                                page: 0, // Reset to first page
                              ),
                            );
                          }
                          : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            column.label,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (column.sortable) ...[
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                isCurrentSort
                                    ? (isDescending
                                        ? Icons.arrow_drop_down
                                        : Icons.arrow_drop_up)
                                    : Icons.unfold_more,
                                size: 16,
                                color:
                                    isCurrentSort
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                              ),
                              // Show loading spinner when this column is being sorted
                              if (_isLoading && isCurrentSort)
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildTableBody(List<TableColumnConfig<T>> visibleColumns) {
    return SingleChildScrollView(
      child: Column(
        children:
            _currentData!.items.map((item) {
              final isSelected = _selectedItem == item;
              return GestureDetector(
                onTap:
                    widget.onRowTap != null
                        ? () {
                          setState(() {
                            _selectedItem = isSelected ? null : item;
                          });
                          widget.onRowTap!(item);
                        }
                        : null,
                onDoubleTap:
                    widget.onRowDoubleTap != null
                        ? () => widget.onRowDoubleTap!(item)
                        : null,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : null,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children:
                        visibleColumns.map((column) {
                          return Expanded(
                            flex: _getColumnFlex(column.width),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: column.cellBuilder(item),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildPagination() {
    if (_currentData == null) return const SizedBox.shrink();

    final data = _currentData!;
    final startIndex = data.page * data.pageSize + 1;
    final endIndex = ((data.page + 1) * data.pageSize).clamp(
      0,
      data.totalCount,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $startIndex to $endIndex of ${data.totalCount} entries',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Row(
            children: [
              DropdownButton<int>(
                value: _currentQuery.pageSize,
                items:
                    [10, 25, 50, 100].map((size) {
                      return DropdownMenuItem(
                        value: size,
                        child: Text('$size per page'),
                      );
                    }).toList(),
                onChanged: (size) {
                  if (size != null) _onPageSizeChanged(size);
                },
              ),
              const SizedBox(width: 16),
              _buildPaginationControls(data),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(PagedResult<T> data) {
    return Row(
      children: [
        IconButton(
          onPressed:
              data.hasPreviousPage ? () => _onPageChanged(data.page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('${data.page + 1} of ${data.totalPages}'),
        IconButton(
          onPressed:
              data.hasNextPage ? () => _onPageChanged(data.page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  int _getColumnFlex(TableColumnWidth width) {
    if (width is FlexColumnWidth) {
      return (width.value * 100).toInt();
    }
    return 100; // Default flex
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filters'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    widget.dataProvider.availableFilters.map((filter) {
                      return _buildFilterWidget(filter);
                    }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _activeFilters.clear();
                  });
                  _updateQuery(_currentQuery.copyWith(filters: {}));
                  Navigator.of(context).pop();
                },
                child: const Text('Clear All'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
    );
  }

  Widget _buildFilterWidget(TableFilter filter) {
    switch (filter.type) {
      case FilterType.dropdown:
        return DropdownButtonFormField<dynamic>(
          decoration: InputDecoration(labelText: filter.label),
          value: _activeFilters[filter.key],
          items: [
            const DropdownMenuItem(value: null, child: Text('All')),
            ...filter.options?.map((option) {
                  return DropdownMenuItem(
                    value: option.value,
                    child: Text(option.label),
                  );
                }) ??
                [],
          ],
          onChanged: (value) => _onFilterChanged(filter.key, value),
        );
      case FilterType.checkbox:
        return CheckboxListTile(
          title: Text(filter.label),
          value: _activeFilters[filter.key] ?? false,
          onChanged: (value) => _onFilterChanged(filter.key, value),
        );
      default:
        return TextField(
          decoration: InputDecoration(labelText: filter.label),
          onChanged: (value) => _onFilterChanged(filter.key, value),
        );
    }
  }
}

/// ✅ UNIVERSAL TABLE UTILITIES - Like ImageUtils for images
class UniversalTable {
  /// Quick table creation - most common use case
  static UniversalTableWidget<T> create<T>({
    required Future<PagedResult<T>> Function(Map<String, dynamic>) fetchData,
    required List<TableColumnConfig<T>> columns,
    String title = '',
    String searchHint = 'Search...',
    String emptyStateMessage = 'No data available',
    List<TableFilter>? filters,
    Widget? headerActions,
    void Function(T)? onRowTap,
    void Function(T)? onRowDoubleTap,
    int defaultPageSize = 25,
  }) {
    final provider = _QuickTableProvider<T>(
      fetchDataFunction: fetchData,
      columns: columns,
      filters: filters ?? [],
      emptyMessage: emptyStateMessage,
    );

    return UniversalTableWidget<T>(
      dataProvider: provider,
      title: title,
      searchHint: searchHint,
      headerActions: headerActions,
      onRowTap: onRowTap,
      onRowDoubleTap: onRowDoubleTap,
      defaultPageSize: defaultPageSize,
    );
  }

  /// Helper: Create standard text cell
  static Widget textCell(String text, {TextStyle? style}) {
    return Text(
      text,
      style: style ?? const TextStyle(fontSize: 14),
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Helper: Create status badge cell
  static Widget statusCell(String status, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (color ?? Colors.blue).withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color ?? Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Helper: Create currency cell
  static Widget currencyCell(double amount, {String currency = 'BAM'}) {
    return textCell(
      '${amount.toStringAsFixed(2)} $currency',
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  }

  /// Helper: Create date cell
  static Widget dateCell(DateTime? date) {
    if (date == null) return textCell('N/A');
    return textCell(date.toLocal().toString().split(' ')[0]);
  }

  /// Helper: Create column configuration
  static TableColumnConfig<T> column<T>({
    required String key,
    required String label,
    required Widget Function(T) cellBuilder,
    bool sortable = true,
    TableColumnWidth? width,
  }) {
    return TableColumnConfig<T>(
      key: key,
      label: label,
      cellBuilder: cellBuilder,
      sortable: sortable,
      width: width ?? const FlexColumnWidth(1),
    );
  }

  /// Helper: Create filter configuration
  static TableFilter filter({
    required String key,
    required String label,
    required FilterType type,
    List<FilterOption>? options,
  }) {
    return TableFilter(key: key, label: label, type: type, options: options);
  }

  /// Helper: Create priority badge cell
  static Widget priorityCell(String priority, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color ?? Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          priority,
          style: const TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Helper: Create clickable link cell with icon
  static Widget linkCell({
    required String text,
    required VoidCallback onTap,
    IconData? icon,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, size: 18, color: Colors.grey[600]),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: color ?? Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper: Create icon action button cell
  static Widget iconActionCell({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    Color? color,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      constraints: const BoxConstraints(),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      color: color,
      onPressed: onPressed,
    );
  }
}

/// Simple implementation for quick tables
class _QuickTableProvider<T> extends BaseTableProvider<T> {
  final Future<PagedResult<T>> Function(Map<String, dynamic>) fetchDataFunction;
  final List<TableColumnConfig<T>> _columns;
  final List<TableFilter> _filters;
  final String emptyMessage;

  _QuickTableProvider({
    required this.fetchDataFunction,
    required List<TableColumnConfig<T>> columns,
    required List<TableFilter> filters,
    required this.emptyMessage,
  }) : _columns = columns,
       _filters = filters;

  @override
  List<TableColumnConfig<T>> get columns => _columns;

  @override
  List<TableFilter> get availableFilters => _filters;

  @override
  String get emptyStateMessage => emptyMessage;

  @override
  Future<PagedResult<T>> fetchData(TableQuery query) async {
    final params = <String, dynamic>{
      'page': query.page + 1, // Backend expects 1-based
      'pageSize': query.pageSize,
    };

    if (query.searchTerm?.isNotEmpty == true) {
      params['searchTerm'] = query.searchTerm;
    }

    if (query.sortBy?.isNotEmpty == true) {
      params['sortBy'] = query.sortBy;
      params['sortDesc'] = query.sortDescending;
    }

    query.filters.forEach((key, value) {
      if (value != null) {
        params[key] = value;
      }
    });

    return await fetchDataFunction(params);
  }
}
