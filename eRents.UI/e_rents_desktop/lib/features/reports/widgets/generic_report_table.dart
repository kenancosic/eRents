import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/widgets/custom_table_widget.dart';
import 'package:e_rents_desktop/features/reports/providers/base_report_provider.dart';
import 'package:e_rents_desktop/base/base_provider.dart';

/// Generic report table that handles common table functionality
class GenericReportTable<T, P extends BaseReportProvider<T>>
    extends StatefulWidget {
  final P provider;
  final List<DataColumn> columns;
  final Map<int, TableColumnWidth> columnWidths;
  final List<DataCell> Function(T) cellsBuilder;
  final String Function(T) searchStringBuilder;
  final Widget emptyStateWidget;

  const GenericReportTable({
    super.key,
    required this.provider,
    required this.columns,
    required this.columnWidths,
    required this.cellsBuilder,
    required this.searchStringBuilder,
    required this.emptyStateWidget,
  });

  @override
  State<GenericReportTable<T, P>> createState() =>
      _GenericReportTableState<T, P>();
}

class _GenericReportTableState<T, P extends BaseReportProvider<T>>
    extends State<GenericReportTable<T, P>> {
  late P _provider;
  bool _initialFetchDone = false;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _provider = widget.provider;

    // Trigger data fetch when widget is initialized, using a microtask to avoid
    // calling setState during build
    if (_provider.items.isEmpty && !_initialFetchDone) {
      _initialFetchDone = true;
      Future.microtask(() {
        if (_mounted) {
          _provider.fetchItems();
        }
      });
    }
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  @override
  void didUpdateWidget(GenericReportTable<T, P> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the provider changed, update the local reference
    if (widget.provider != oldWidget.provider) {
      _provider = widget.provider;

      // Re-fetch data if the provider changed and has no items
      if (_provider.items.isEmpty) {
        Future.microtask(() {
          if (_mounted) {
            _provider.fetchItems();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _provider,
      builder: (context, _) {
        final data = _provider.items;
        final isLoading = _provider.state == ViewState.Busy;
        final hasError = _provider.state == ViewState.Error;

        debugPrint(
          'GenericReportTable build: isLoading=$isLoading, data.length=${data.length}, hasError=$hasError',
        );

        // Show loading indicator when provider is explicitly in busy state
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show error state
        if (hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading data: ${_provider.errorMessage ?? "Unknown error"}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  onPressed: () {
                    _provider.fetchItems();
                  },
                ),
              ],
            ),
          );
        }

        // Show empty state if no data is available and we're not loading
        if (data.isEmpty) {
          // Only initiate a fetch if this is the first time we're empty
          if (!_initialFetchDone) {
            _initialFetchDone = true;
            // Trigger a fetch after the build completes
            Future.microtask(() {
              if (_mounted) {
                debugPrint(
                  'GenericReportTable: initiating fetch due to empty data',
                );
                _provider.fetchItems();
              }
            });
          }
          return widget.emptyStateWidget;
        }

        // Return the table widget with data
        return CustomTableWidget<T>(
          title: _provider.getReportTitleWithDateRange(),
          data: data,
          columns: widget.columns,
          columnWidths: widget.columnWidths,
          cellsBuilder: widget.cellsBuilder,
          searchStringBuilder: widget.searchStringBuilder,
          emptyStateWidget: widget.emptyStateWidget,
        );
      },
    );
  }
}
