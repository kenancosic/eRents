import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/table_query.dart';
import 'core/table_types.dart';
import 'core/table_columns.dart';
import 'core/table_filters.dart';
import 'providers/base_table_provider.dart';
import '../custom_search_bar.dart';

/// Main Universal Table Widget - Complete table solution using modular architecture
class CustomTableWidget<T> extends StatefulWidget {
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

  const CustomTableWidget({
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
  State<CustomTableWidget<T>> createState() => _CustomTableWidgetState<T>();
}

class _CustomTableWidgetState<T> extends State<CustomTableWidget<T>> {
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
                  color: Colors.white.withValues(alpha: 0.7),
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
                              newSortBy = ''; // Use empty string to clear sort
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
                            ? Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1)
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
                  context.pop();
                },
                child: const Text('Clear All'),
              ),
              TextButton(
                onPressed: () => context.pop(),
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
