import 'package:flutter/material.dart';

// A reusable data table widget with search, filter, and pagination
class TableWidget<T> extends StatefulWidget {
  final String title;
  final List<T> data;
  final List<DataColumn> columns;
  final List<DataCell> Function(T) cellsBuilder;
  final String Function(T) searchStringBuilder;
  final Map<String, List<Filter>> filterOptions;
  final int defaultRowsPerPage;
  final Widget? emptyStateWidget;
  final bool Function(T, String, dynamic)? filterFunction;
  final Map<int, TableColumnWidth>? columnWidths;
  final double? dataRowHeight;

  const TableWidget({
    Key? key,
    required this.title,
    required this.data,
    required this.columns,
    required this.cellsBuilder,
    required this.searchStringBuilder,
    this.filterOptions = const {},
    this.defaultRowsPerPage = 10,
    this.emptyStateWidget,
    this.filterFunction,
    this.columnWidths,
    this.dataRowHeight,
  }) : super(key: key);

  @override
  _TableWidgetState<T> createState() => _TableWidgetState<T>();
}

class _TableWidgetState<T> extends State<TableWidget<T>> {
  late List<T> _filteredData;
  String _searchTerm = '';
  int _currentPage = 0;
  late int _rowsPerPage;
  Map<String, dynamic> _activeFilters = {};
  int? _sortColumnIndex;
  bool _sortAscending = true;
  final List<int> _availableRowsPerPage = [10, 25, 50, 100];

  @override
  void initState() {
    super.initState();
    _filteredData = List.from(widget.data);
    _rowsPerPage = widget.defaultRowsPerPage;
  }

  @override
  void didUpdateWidget(TableWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _applyFiltersAndSearch();
    }
  }

  void _applyFiltersAndSearch() {
    setState(() {
      _filteredData =
          widget.data.where((item) {
            // Apply search filter
            if (_searchTerm.isNotEmpty) {
              String searchString =
                  widget.searchStringBuilder(item).toLowerCase();
              if (!searchString.contains(_searchTerm.toLowerCase())) {
                return false;
              }
            }

            // Apply column filters
            for (final entry in _activeFilters.entries) {
              if (entry.value != null) {
                // Use custom filter function if provided
                if (widget.filterFunction != null) {
                  if (!widget.filterFunction!(item, entry.key, entry.value)) {
                    return false;
                  }
                } else {
                  // Default filter implementation - this can be overridden by providing filterFunction
                  // For basic equality checking, assuming the item has a property matching the filter key
                  try {
                    dynamic itemValue = _getPropertyValue(item, entry.key);
                    if (itemValue != entry.value) {
                      return false;
                    }
                  } catch (e) {
                    // If we can't get the property, we assume it doesn't match
                    return false;
                  }
                }
              }
            }

            return true;
          }).toList();

      // Reset to first page when filters change
      _currentPage = 0;
    });
  }

  // Helper method to get a property value by name from an object
  dynamic _getPropertyValue(T item, String propertyName) {
    // This is a simplified approach that may need to be adjusted based on your data model
    if (item is Map) {
      return (item as Map)[propertyName];
    } else {
      // For objects, we would ideally use reflection
      // This is placeholder logic
      return null;
    }
  }

  void _sort<U>(U Function(T) getField, int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      _filteredData.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);

        int comparison;
        if (aValue == null && bValue == null) {
          comparison = 0;
        } else if (aValue == null) {
          comparison = -1;
        } else if (bValue == null) {
          comparison = 1;
        } else if (aValue is Comparable) {
          comparison = (aValue as Comparable).compareTo(bValue);
        } else {
          comparison = aValue.toString().compareTo(bValue.toString());
        }

        return ascending ? comparison : -comparison;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate pagination values
    final int startIndex = _currentPage * _rowsPerPage;
    final endIndex =
        (startIndex + _rowsPerPage > _filteredData.length)
            ? _filteredData.length
            : startIndex + _rowsPerPage;

    // Ensure correct typing for pageItems
    final List<T> pageItems =
        (startIndex < _filteredData.length)
            ? _filteredData.sublist(startIndex, endIndex)
            : [];

    final totalPages = (_filteredData.length / _rowsPerPage).ceil();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed height header
            _buildHeader(context),
            const SizedBox(height: 16),
            // Expandable table area
            Expanded(
              child:
                  _filteredData.isEmpty
                      ? Center(
                        child:
                            widget.emptyStateWidget ??
                            const Text('No data available'),
                      )
                      : _buildTableContent(pageItems),
            ),
            const SizedBox(height: 16),
            // Fixed height pagination
            _buildPagination(context, startIndex, endIndex, totalPages),
          ],
        ),
      ),
    );
  }

  // Build the scrollable table content
  Widget _buildTableContent(List<T> pageItems) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Theme(
              data: Theme.of(context).copyWith(
                dataTableTheme: DataTableTheme.of(context).copyWith(
                  headingTextStyle: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  dataTextStyle: Theme.of(context).textTheme.bodyMedium,
                  horizontalMargin: 0, // No margin to use full width
                  columnSpacing: 12, // Reduce spacing to fit more content
                  headingRowHeight: 56,
                  dataRowMaxHeight: widget.dataRowHeight ?? 56,
                  dividerThickness: 1,
                ),
              ),
              child: DataTable(
                columns: widget.columns,
                rows:
                    pageItems
                        .map(
                          (item) => DataRow(cells: widget.cellsBuilder(item)),
                        )
                        .toList(),
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                border: TableBorder(
                  horizontalInside: BorderSide(
                    width: 1,
                    color: Colors.grey.shade200,
                  ),
                  bottom: BorderSide(width: 1, color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Build the table header with title, search and filters
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SearchBar(
              onChanged: (value) {
                setState(() {
                  _searchTerm = value;
                  _applyFiltersAndSearch();
                });
              },
            ),
          ),
        ),
        if (widget.filterOptions.isNotEmpty)
          FilterButton(
            filterOptions: widget.filterOptions,
            activeFilters: _activeFilters,
            onFilterChanged: (filterName, value) {
              setState(() {
                _activeFilters[filterName] = value;
                _applyFiltersAndSearch();
              });
            },
          ),
      ],
    );
  }

  // Build pagination controls
  Widget _buildPagination(
    BuildContext context,
    int startIndex,
    int endIndex,
    int totalPages,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing ${startIndex + 1} to $endIndex of ${_filteredData.length} entries',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Row(
          children: [
            DropdownButton<int>(
              value: _rowsPerPage,
              items:
                  _availableRowsPerPage
                      .map(
                        (value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value per page'),
                        ),
                      )
                      .toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _rowsPerPage = newValue;
                    _currentPage = 0; // Reset to first page
                  });
                }
              },
            ),
            const SizedBox(width: 16),
            PaginationControls(
              currentPage: _currentPage,
              totalPages: totalPages,
              onPageChanged: (page) => setState(() => _currentPage = page),
            ),
          ],
        ),
      ],
    );
  }
}

class SearchBar extends StatefulWidget {
  final Function(String) onChanged;
  final String hintText;

  const SearchBar({
    Key? key,
    required this.onChanged,
    this.hintText = 'Search...',
  }) : super(key: key);

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon:
            _controller.text.isNotEmpty
                ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                  },
                )
                : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
      ),
      onChanged: widget.onChanged,
    );
  }
}

// Filter Model and Widget
class Filter {
  final String label;
  final dynamic value;

  Filter({required this.label, required this.value});
}

class FilterButton extends StatelessWidget {
  final Map<String, List<Filter>> filterOptions;
  final Map<String, dynamic> activeFilters;
  final Function(String, dynamic) onFilterChanged;

  const FilterButton({
    Key? key,
    required this.filterOptions,
    required this.activeFilters,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      icon: const Icon(Icons.filter_list),
      tooltip: 'Filter',
      itemBuilder: (BuildContext context) {
        return filterOptions.entries.map((entry) {
          final String filterName = entry.key;
          final List<Filter> options = entry.value;

          return PopupMenuItem<void>(
            enabled: false, // Disable the item itself
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filterName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                ),
                const Divider(),
                ...options.map((option) {
                  return CheckboxListTile(
                    title: Text(option.label),
                    value: activeFilters[filterName] == option.value,
                    onChanged: (bool? checked) {
                      if (checked == true) {
                        onFilterChanged(filterName, option.value);
                      } else {
                        onFilterChanged(filterName, null);
                      }
                      Navigator.pop(context);
                    },
                    dense: true,
                  );
                }).toList(),
                const SizedBox(height: 8),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}

// Pagination Controls Widget
class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;

  const PaginationControls({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return const SizedBox.shrink(); // Don't show pagination for single page
    }

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_left),
          onPressed:
              currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
        ),
        ..._buildPageButtons(context),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_right),
          onPressed:
              currentPage < totalPages - 1
                  ? () => onPageChanged(currentPage + 1)
                  : null,
        ),
      ],
    );
  }

  List<Widget> _buildPageButtons(BuildContext context) {
    const int maxVisiblePages = 5;
    final List<Widget> widgets = [];

    // Determine the range of pages to display
    int startPage = 0;
    int endPage = totalPages - 1;

    if (totalPages > maxVisiblePages) {
      // Calculate the start and end of the visible page range
      startPage = (currentPage - (maxVisiblePages ~/ 2)).clamp(
        0,
        totalPages - maxVisiblePages,
      );
      endPage = startPage + maxVisiblePages - 1;

      // Add first page and ellipsis if needed
      if (startPage > 0) {
        widgets.add(_pageButton(context, 0));
        if (startPage > 1) widgets.add(const Text('...'));
      }

      // Add the visible pages
      for (int i = startPage; i <= endPage; i++) {
        widgets.add(_pageButton(context, i));
      }

      // Add ellipsis and last page if needed
      if (endPage < totalPages - 1) {
        if (endPage < totalPages - 2) widgets.add(const Text('...'));
        widgets.add(_pageButton(context, totalPages - 1));
      }
    } else {
      // If we have fewer pages than maxVisiblePages, just show them all
      for (int i = 0; i < totalPages; i++) {
        widgets.add(_pageButton(context, i));
      }
    }

    return widgets;
  }

  Widget _pageButton(BuildContext context, int page) {
    final bool isCurrentPage = page == currentPage;

    return InkWell(
      onTap: isCurrentPage ? null : () => onPageChanged(page),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: isCurrentPage ? Theme.of(context).primaryColor : null,
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Text(
          '${page + 1}',
          style: TextStyle(
            color: isCurrentPage ? Colors.white : null,
            fontWeight: isCurrentPage ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }
}
