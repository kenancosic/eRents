import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/base_provider.dart';

/// Generic report table that handles common table functionality
class GenericReportTable<T, P extends BaseProvider<T>> extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return provider.items.isEmpty
        ? emptyStateWidget
        : LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: constraints.maxWidth,
                child: DataTable(
                  columns: columns,
                  columnSpacing: 16,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 64,
                  horizontalMargin: 16,
                  rows:
                      provider.items
                          .map((item) => DataRow(cells: cellsBuilder(item)))
                          .toList(),
                ),
              ),
            );
          },
        );
  }
}
