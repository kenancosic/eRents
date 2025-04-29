import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/reports/providers/tenant_report_provider.dart';
import 'package:e_rents_desktop/models/reports/tenant_report_item.dart';
import 'package:e_rents_desktop/widgets/custom_table_widget.dart';
import 'package:e_rents_desktop/utils/formatters.dart';

class TenantReportTable extends StatelessWidget {
  const TenantReportTable({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TenantReportProvider>(context);
    final reportItems = provider.items;

    // Define columns for CustomTableWidget
    final List<DataColumn> columns = [
      const DataColumn(label: Text('Tenant')),
      const DataColumn(label: Text('Property')),
      const DataColumn(label: Text('Lease Start')),
      const DataColumn(label: Text('Lease End')),
      const DataColumn(label: Text('Cost of Rent')),
      const DataColumn(label: Text('Total Paid Rent')),
    ];

    // Define how to build cells for each item
    List<DataCell> cellsBuilder(TenantReportItem item) {
      return [
        DataCell(Text(item.tenantName)),
        DataCell(Text(item.propertyName)),
        DataCell(Text(item.dateFrom)),
        DataCell(Text(item.dateTo)),
        DataCell(Text(kCurrencyFormat.format(item.costOfRent))),
        DataCell(Text(kCurrencyFormat.format(item.totalPaidRent))),
      ];
    }

    // Define a search string builder (can be simple for now)
    String searchStringBuilder(TenantReportItem item) {
      return '${item.tenantName} ${item.propertyName} ${item.dateFrom} ${item.dateTo}';
    }

    // Define column widths for better layout
    final Map<int, TableColumnWidth> columnWidths = {
      0: const FlexColumnWidth(1.5), // Tenant
      1: const FlexColumnWidth(2), // Property
      2: const FlexColumnWidth(1), // Lease Start
      3: const FlexColumnWidth(1), // Lease End
      4: const FlexColumnWidth(1), // Cost of Rent
      5: const FlexColumnWidth(1), // Total Paid Rent
    };

    return CustomTableWidget<TenantReportItem>(
      data: reportItems,
      columns: columns,
      cellsBuilder: cellsBuilder,
      searchStringBuilder: searchStringBuilder,
      columnWidths: columnWidths,
      emptyStateWidget: const Center(child: Text('No tenant data available')),
      // title: 'Tenant Report', // Optional title within the table card
    );
  }
}
