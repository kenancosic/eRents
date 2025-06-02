import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/reports/providers/reports_state_provider.dart';
import 'package:e_rents_desktop/models/reports/financial_report_item.dart';
import 'package:e_rents_desktop/widgets/custom_table_widget.dart';
import 'package:e_rents_desktop/utils/formatters.dart';

class FinancialReportTable extends StatelessWidget {
  const FinancialReportTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsStateProvider>(
      builder: (context, reportsProvider, child) {
        final reportItems = reportsProvider.financialReportData ?? [];

        final List<DataColumn> columns = [
          const DataColumn(label: Text('Date From')),
          const DataColumn(label: Text('Date To')),
          const DataColumn(label: Text('Property')),
          const DataColumn(label: Text('Total Rent')),
          const DataColumn(label: Text('Maintenance Costs')),
          const DataColumn(label: Text('Total')),
        ];

        List<DataCell> cellsBuilder(FinancialReportItem item) {
          return [
            DataCell(Text(item.dateFrom)),
            DataCell(Text(item.dateTo)),
            DataCell(Text(item.property)),
            DataCell(Text(kCurrencyFormat.format(item.totalRent))),
            DataCell(Text(kCurrencyFormat.format(item.maintenanceCosts))),
            DataCell(Text(kCurrencyFormat.format(item.total))),
          ];
        }

        String searchStringBuilder(FinancialReportItem item) {
          return '${item.property} ${item.dateFrom} ${item.dateTo}';
        }

        final Map<int, TableColumnWidth> columnWidths = {
          0: const FlexColumnWidth(1), // Date From
          1: const FlexColumnWidth(1), // Date To
          2: const FlexColumnWidth(2), // Property
          3: const FlexColumnWidth(1), // Total Rent
          4: const FlexColumnWidth(1.2), // Maintenance Costs
          5: const FlexColumnWidth(1), // Total
        };

        return CustomTableWidget<FinancialReportItem>(
          data: reportItems,
          columns: columns,
          cellsBuilder: cellsBuilder,
          searchStringBuilder: searchStringBuilder,
          columnWidths: columnWidths,
          emptyStateWidget: const Center(
            child: Text('No financial data available for the selected period'),
          ),
        );
      },
    );
  }
}
