import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';

class ReportTable extends StatelessWidget {
  final String reportType;
  final DateTime startDate;
  final DateTime endDate;

  const ReportTable({
    super.key,
    required this.reportType,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: DataTable2(
        columns: _getColumns(),
        rows: _getRows(),
        border: TableBorder.all(color: Colors.grey[300]!),
        bottomMargin: 20,
        horizontalMargin: 20,
        columnSpacing: 20,
        minWidth: 600,
        dataRowHeight: 50,
        headingRowHeight: 50,
        headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
        showBottomBorder: true,
        showCheckboxColumn: false,
        sortAscending: true,
        sortColumnIndex: 0,
        empty: Center(
          child: Text(
            'No data available for the selected period',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  List<DataColumn> _getColumns() {
    switch (reportType) {
      case 'Financial Report':
        return const [
          DataColumn2(label: Text('Date'), size: ColumnSize.L),
          DataColumn2(label: Text('Property'), size: ColumnSize.L),
          DataColumn2(label: Text('Income'), size: ColumnSize.M),
          DataColumn2(label: Text('Expenses'), size: ColumnSize.M),
          DataColumn2(label: Text('Net'), size: ColumnSize.M),
        ];
      case 'Occupancy Report':
        return const [
          DataColumn2(label: Text('Property'), size: ColumnSize.L),
          DataColumn2(label: Text('Total Units'), size: ColumnSize.S),
          DataColumn2(label: Text('Occupied'), size: ColumnSize.S),
          DataColumn2(label: Text('Vacant'), size: ColumnSize.S),
          DataColumn2(label: Text('Occupancy Rate'), size: ColumnSize.M),
        ];
      case 'Maintenance Report':
        return const [
          DataColumn2(label: Text('Date'), size: ColumnSize.L),
          DataColumn2(label: Text('Property'), size: ColumnSize.L),
          DataColumn2(label: Text('Issue'), size: ColumnSize.L),
          DataColumn2(label: Text('Status'), size: ColumnSize.M),
          DataColumn2(label: Text('Cost'), size: ColumnSize.M),
        ];
      case 'Tenant Report':
        return const [
          DataColumn2(label: Text('Name'), size: ColumnSize.L),
          DataColumn2(label: Text('Property'), size: ColumnSize.L),
          DataColumn2(label: Text('Lease Start'), size: ColumnSize.M),
          DataColumn2(label: Text('Lease End'), size: ColumnSize.M),
          DataColumn2(label: Text('Status'), size: ColumnSize.M),
        ];
      default:
        return [];
    }
  }

  List<DataRow> _getRows() {
    switch (reportType) {
      case 'Financial Report':
        return [
          DataRow(
            cells: [
              const DataCell(Text('2024-03-01')),
              const DataCell(Text('123 Main St')),
              const DataCell(Text('\$2,500')),
              const DataCell(Text('\$500')),
              const DataCell(Text('\$2,000')),
            ],
          ),
          DataRow(
            cells: [
              const DataCell(Text('2024-03-01')),
              const DataCell(Text('456 Oak Ave')),
              const DataCell(Text('\$3,000')),
              const DataCell(Text('\$800')),
              const DataCell(Text('\$2,200')),
            ],
          ),
        ];
      case 'Occupancy Report':
        return [
          DataRow(
            cells: [
              const DataCell(Text('123 Main St')),
              const DataCell(Text('10')),
              const DataCell(Text('9')),
              const DataCell(Text('1')),
              const DataCell(Text('90%')),
            ],
          ),
          DataRow(
            cells: [
              const DataCell(Text('456 Oak Ave')),
              const DataCell(Text('15')),
              const DataCell(Text('14')),
              const DataCell(Text('1')),
              const DataCell(Text('93%')),
            ],
          ),
        ];
      case 'Maintenance Report':
        return [
          DataRow(
            cells: [
              const DataCell(Text('2024-03-01')),
              const DataCell(Text('123 Main St')),
              const DataCell(Text('Leaking Roof')),
              const DataCell(Text('In Progress')),
              const DataCell(Text('\$1,500')),
            ],
          ),
          DataRow(
            cells: [
              const DataCell(Text('2024-03-02')),
              const DataCell(Text('456 Oak Ave')),
              const DataCell(Text('Broken Window')),
              const DataCell(Text('Completed')),
              const DataCell(Text('\$300')),
            ],
          ),
        ];
      case 'Tenant Report':
        return [
          DataRow(
            cells: [
              const DataCell(Text('John Doe')),
              const DataCell(Text('123 Main St')),
              const DataCell(Text('2024-01-01')),
              const DataCell(Text('2025-01-01')),
              const DataCell(Text('Active')),
            ],
          ),
          DataRow(
            cells: [
              const DataCell(Text('Jane Smith')),
              const DataCell(Text('456 Oak Ave')),
              const DataCell(Text('2024-02-01')),
              const DataCell(Text('2025-02-01')),
              const DataCell(Text('Active')),
            ],
          ),
        ];
      default:
        return [];
    }
  }
}
