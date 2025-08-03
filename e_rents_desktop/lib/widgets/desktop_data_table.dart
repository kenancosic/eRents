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

  const DesktopDataTable({
    Key? key,
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
  }) : super(key: key);

  @override
  State<DesktopDataTable<T>> createState() => _DesktopDataTableState<T>();
}

class _DesktopDataTableState<T> extends State<DesktopDataTable<T>> {
  late ScrollController _scrollController;

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
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
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
              rows: widget.rowsBuilder(context, widget.items),
            ),
          ),
        ),
      ),
    );
  }
}
