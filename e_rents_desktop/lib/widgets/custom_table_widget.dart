import 'package:flutter/material.dart';

// A reusable data table widget with search, filter, and pagination
class CustomTableWidget<T> extends StatefulWidget {
  final String title;
  final List<T> data;
  final List<DataColumn> columns;
  final List<DataCell> Function(T) cellsBuilder;
  final String Function(T) searchStringBuilder;
  final int defaultRowsPerPage;
  final Widget? emptyStateWidget;
  final Map<int, TableColumnWidth>? columnWidths;
  final double? dataRowHeight;
  final void Function(T)? onRowDoubleTap;
  final void Function(T)? onRowTap;

  const CustomTableWidget({
    super.key,
    this.title = '',
    required this.data,
    required this.columns,
    required this.cellsBuilder,
    required this.searchStringBuilder,
    this.defaultRowsPerPage = 10,
    this.emptyStateWidget,
    this.columnWidths,
    this.dataRowHeight,
    this.onRowDoubleTap,
    this.onRowTap,
  });

  @override
  _CustomTableWidgetState<T> createState() => _CustomTableWidgetState<T>();
}

class _CustomTableWidgetState<T> extends State<CustomTableWidget<T>> {
  late List<T> _filteredData;
  int _currentPage = 0;
  late int _rowsPerPage;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  final List<int> _availableRowsPerPage = [10, 25, 50, 100];
  T? _selectedItem;

  @override
  void initState() {
    super.initState();
    _filteredData = List.from(widget.data);
    _rowsPerPage = widget.defaultRowsPerPage;
  }

  @override
  void didUpdateWidget(CustomTableWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      setState(() {
        _filteredData = List.from(widget.data);
      });
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
            if (widget.title.isNotEmpty)
              Column(
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
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

  // Build the scrollable table content with sticky headers
  Widget _buildTableContent(List<T> pageItems) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Define styles and widths
        final columnWidths = _getEffectiveColumnWidths();
        final headerStyle = _getHeaderTextStyle(context);
        final dataStyle = Theme.of(context).textTheme.bodyMedium;
        const double headerHeight = 56.0;

        // Build table components
        final headerRow = _buildHeaderRow(
          headerHeight,
          headerStyle,
          columnWidths,
        );
        final dataRows = _buildDataRows(pageItems, constraints, columnWidths);

        return Column(children: [headerRow, dataRows]);
      },
    );
  }

  // Get effective column widths, falling back to default if not provided
  Map<int, TableColumnWidth> _getEffectiveColumnWidths() {
    return widget.columnWidths ??
        widget.columns.asMap().map(
          (i, _) => MapEntry(i, const FlexColumnWidth(1)),
        );
  }

  // Get the header text style
  TextStyle? _getHeaderTextStyle(BuildContext context) {
    return Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, height: 1.2);
  }

  // Build the fixed header row
  Widget _buildHeaderRow(
    double headerHeight,
    TextStyle? headerStyle,
    Map<int, TableColumnWidth> columnWidths,
  ) {
    return Container(
      height: headerHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 1, color: Colors.grey.shade300),
        ),
        color: Colors.grey.shade50,
      ),
      child: Row(
        children:
            widget.columns.asMap().entries.map((entry) {
              return _buildHeaderCell(
                entry.key,
                entry.value,
                columnWidths,
                headerStyle,
              );
            }).toList(),
      ),
    );
  }

  // Build an individual header cell
  Widget _buildHeaderCell(
    int columnIndex,
    DataColumn column,
    Map<int, TableColumnWidth> columnWidths,
    TextStyle? headerStyle,
  ) {
    final TableColumnWidth columnWidth =
        columnWidths[columnIndex] ?? const FlexColumnWidth(1);

    // Determine flex value for the column
    double? flex;
    if (columnWidth is FlexColumnWidth) {
      flex = columnWidth.value;
    }

    return Expanded(
      flex: (flex != null) ? (flex * 100).toInt() : 100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child:
              (column.label is Text)
                  ? Text(
                    (column.label as Text).data ?? '',
                    style: headerStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                  : column.label,
        ),
      ),
    );
  }

  // Build the scrollable data rows section
  Widget _buildDataRows(
    List<T> pageItems,
    BoxConstraints constraints,
    Map<int, TableColumnWidth> columnWidths,
  ) {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SizedBox(
          width: constraints.maxWidth,
          child: Column(
            children:
                pageItems.map((item) {
                  return _buildDataRow(item, columnWidths);
                }).toList(),
          ),
        ),
      ),
    );
  }

  // Build an individual data row
  Widget _buildDataRow(T item, Map<int, TableColumnWidth> columnWidths) {
    final cells = widget.cellsBuilder(item);
    final bool isSelected = _selectedItem == item;

    Widget rowWidget = Container(
      height: widget.dataRowHeight ?? 56.0,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 1, color: Colors.grey.shade200),
        ),
        color:
            isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      ),
      child: Row(
        children:
            cells.asMap().entries.map((entry) {
              return _buildDataCell(entry.key, entry.value, columnWidths);
            }).toList(),
      ),
    );

    // Add click functionality if callbacks are provided
    if (widget.onRowTap != null || widget.onRowDoubleTap != null) {
      rowWidget = GestureDetector(
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
        child: MouseRegion(cursor: SystemMouseCursors.click, child: rowWidget),
      );
    }

    return rowWidget;
  }

  // Build an individual data cell
  Widget _buildDataCell(
    int cellIndex,
    DataCell cell,
    Map<int, TableColumnWidth> columnWidths,
  ) {
    final TableColumnWidth columnWidth =
        columnWidths[cellIndex] ?? const FlexColumnWidth(1);

    // Determine flex value for the cell
    double? flex;
    if (columnWidth is FlexColumnWidth) {
      flex = columnWidth.value;
    }

    return Expanded(
      flex: (flex != null) ? (flex * 100).toInt() : 100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Align(alignment: Alignment.centerLeft, child: cell.child),
      ),
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

// Filter Model
class Filter {
  final String label;
  final dynamic value;

  Filter({required this.label, required this.value});
}

// Pagination Controls Widget
class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

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
