import 'package:flutter/material.dart';

class DesktopDataTable<T> extends StatefulWidget {
  final List<T> items;
  final List<DataColumn> columns;
  final List<DataRow> Function(BuildContext context, List<T> items) rowsBuilder;
  final void Function(T item)? onRowTap;
  final int rowsPerPage;
  final bool sortAscending;
  final int? sortColumnIndex;
  final void Function(int? columnIndex, bool ascending)? onSort;
  final bool loading;
  final String? errorMessage;
  final Future<void> Function()? onRefresh;
  final String emptyMessage;
  final List<String>? sortFieldNames; // Field names for API sorting
  // Optional server-side pagination
  final int? totalCount; // When provided, enables server-side pagination mode
  final int? page; // 1-based
  final int? pageSize;
  final void Function(int newPage)? onPageChange; // 1-based

  const DesktopDataTable({
    super.key,
    required this.items,
    required this.columns,
    required this.rowsBuilder,
    this.onRowTap,
    this.rowsPerPage = 10,
    this.sortAscending = true,
    this.sortColumnIndex,
    this.onSort,
    this.loading = false,
    this.errorMessage,
    this.onRefresh,
    this.emptyMessage = 'No data available',
    this.sortFieldNames,
    this.totalCount,
    this.page,
    this.pageSize,
    this.onPageChange,
  });

  @override
  State<DesktopDataTable<T>> createState() => _DesktopDataTableState<T>();
}

class _DesktopDataTableState<T> extends State<DesktopDataTable<T>> {
  late ScrollController _scrollController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DesktopDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clamp current page if the number of items or rowsPerPage changed (client-side mode)
    if (!_isServerMode) {
      final totalPages = _totalPages;
      if (_currentPage >= totalPages) {
        setState(() {
          _currentPage = totalPages == 0 ? 0 : totalPages - 1;
        });
      }
    }
  }

  int get _totalPages {
    if (_isServerMode) {
      final total = widget.totalCount ?? 0;
      final size = widget.pageSize ?? widget.rowsPerPage;
      if (total == 0 || size == 0) return 0;
      return (total / size).ceil();
    } else {
      if (widget.items.isEmpty) return 0;
      return (widget.items.length / widget.rowsPerPage).ceil();
    }
  }

  List<T> get _pagedItems {
    if (_isServerMode) {
      // In server mode, items already correspond to the current page
      return widget.items;
    }
    if (widget.items.isEmpty) return const [];
    final start = _currentPage * widget.rowsPerPage;
    final end = (start + widget.rowsPerPage).clamp(0, widget.items.length);
    return widget.items.sublist(start, end);
  }

  bool get _isServerMode =>
      widget.totalCount != null && widget.onPageChange != null && (widget.page ?? 1) >= 1;

  @override
  Widget build(BuildContext context) {
    if (widget.loading && widget.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${widget.errorMessage}'),
            if (widget.onRefresh != null)
              ElevatedButton(
                onPressed: widget.onRefresh,
                child: const Text('Retry'),
              ),
          ],
        ),
      );
    }

    if (widget.items.isEmpty) {
      return Center(child: Text(widget.emptyMessage));
    }

    // Update columns with sort callbacks if onSort is provided
    List<DataColumn> updatedColumns = widget.columns;
    if (widget.onSort != null) {
      updatedColumns = List<DataColumn>.generate(widget.columns.length, (index) {
        return DataColumn(
          label: widget.columns[index].label,
          tooltip: widget.columns[index].tooltip,
          numeric: widget.columns[index].numeric,
          onSort: (columnIndex, ascending) => widget.onSort!(columnIndex, ascending),
        );
      });
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh ?? () async {},
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  maxWidth: constraints.maxWidth,
                ),
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DataTable(
                          columns: updatedColumns,
                          sortAscending: widget.sortAscending,
                          sortColumnIndex: widget.sortColumnIndex,
                          headingRowColor: WidgetStateProperty.all(
                            Theme.of(context).colorScheme.primaryContainer,
                          ),
                          dataRowColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                            if (states.contains(WidgetState.hovered)) {
                              return Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3);
                            }
                            return null; // Use default color
                          }),
                          headingTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          dataTextStyle: Theme.of(context).textTheme.bodyMedium,
                          rows: widget.rowsBuilder(context, _pagedItems),
                          columnSpacing: 24.0,
                          horizontalMargin: 24.0,
                          dataRowMinHeight: 56.0,
                          dataRowMaxHeight: 72.0,
                          headingRowHeight: 56.0,
                        ),
                        const SizedBox(height: 8),
                        _buildPaginationFooter(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaginationFooter(BuildContext context) {
    final theme = Theme.of(context);
    final total = _isServerMode ? (widget.totalCount ?? 0) : widget.items.length;
    final currentPage1Based = _isServerMode ? (widget.page ?? 1) : (_currentPage + 1);
    final pageSize = _isServerMode ? (widget.pageSize ?? widget.rowsPerPage) : widget.rowsPerPage;
    final start = total == 0 ? 0 : ((currentPage1Based - 1) * pageSize) + 1;
    final end = (currentPage1Based * pageSize).clamp(0, total);
    final totalPages = _totalPages;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Showing $start-$end of $total', style: theme.textTheme.bodySmall),
          const SizedBox(width: 16),
          IconButton(
            tooltip: 'Previous page',
            onPressed: _isServerMode
                ? (currentPage1Based > 1
                    ? () => widget.onPageChange!.call(currentPage1Based - 1)
                    : null)
                : (_currentPage > 0
                    ? () => setState(() => _currentPage -= 1)
                    : null),
            icon: const Icon(Icons.chevron_left),
          ),
          Text('${totalPages == 0 ? 0 : currentPage1Based} / $totalPages', style: theme.textTheme.bodySmall),
          IconButton(
            tooltip: 'Next page',
            onPressed: _isServerMode
                ? (currentPage1Based < totalPages
                    ? () => widget.onPageChange!.call(currentPage1Based + 1)
                    : null)
                : ((_currentPage + 1) < totalPages
                    ? () => setState(() => _currentPage += 1)
                    : null),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

