import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/reports/providers/tenant_report_provider.dart';
import 'package:e_rents_desktop/models/reports/tenant_report_item.dart';

class TenantReportTable extends StatelessWidget {
  const TenantReportTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TenantReportProvider>(context);
    final reportItems = provider.items;

    if (reportItems.isEmpty) {
      return const Center(child: Text('No tenant data available'));
    }

    return Card(
      elevation: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Tenant')),
              DataColumn(label: Text('Property')),
              DataColumn(label: Text('Lease Start')),
              DataColumn(label: Text('Lease End')),
              DataColumn(label: Text('Cost of Rent')),
              DataColumn(label: Text('Total Paid Rent')),
            ],
            columnSpacing: 24,
            rows: reportItems.map((item) => _buildRow(item)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(TenantReportItem item) {
    return DataRow(
      cells: [
        DataCell(Text(item.tenant)),
        DataCell(Text(item.property)),
        DataCell(Text(item.leaseStart)),
        DataCell(Text(item.leaseEnd)),
        DataCell(Text(item.formattedCostOfRent)),
        DataCell(Text(item.formattedTotalPaidRent)),
      ],
    );
  }
}
