import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/reports/providers/financial_report_provider.dart';
import 'package:e_rents_desktop/models/reports/financial_report_item.dart';

class FinancialReportTable extends StatelessWidget {
  const FinancialReportTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinancialReportProvider>(context);
    final reportItems = provider.items;

    if (reportItems.isEmpty) {
      return const Center(
        child: Text('No financial data available for the selected period'),
      );
    }

    return Card(
      elevation: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Date From')),
              DataColumn(label: Text('Date To')),
              DataColumn(label: Text('Property')),
              DataColumn(label: Text('Total Rent')),
              DataColumn(label: Text('Maintenance Costs')),
              DataColumn(label: Text('Total')),
            ],
            columnSpacing: 24,
            rows: reportItems.map((item) => _buildRow(item)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(FinancialReportItem item) {
    return DataRow(
      cells: [
        DataCell(Text(item.dateFrom)),
        DataCell(Text(item.dateTo)),
        DataCell(Text(item.property)),
        DataCell(Text(item.formattedTotalRent)),
        DataCell(Text(item.formattedMaintenanceCosts)),
        DataCell(Text(item.formattedTotal)),
      ],
    );
  }
}
