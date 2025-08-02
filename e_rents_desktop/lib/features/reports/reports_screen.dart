import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/widgets/filters/report_filters.dart';
import 'package:e_rents_desktop/features/reports/providers/reports_provider.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:e_rents_desktop/utils/logger.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        final reportsProvider = Provider.of<ReportsProvider>(
          context,
          listen: false,
        );
        reportsProvider.fetchCurrentReports();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ReportsProvider, AuthProvider>(
      builder: (context, reportsProvider, authProvider, _) {
        if (!authProvider.isAuthenticated) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64),
                SizedBox(height: 16),
                Text('Please log in to view reports'),
              ],
            ),
          );
        }

        return _FinancialReportContent(reportsProvider: reportsProvider);
      },
    );
  }
}

class _FinancialReportContent extends StatelessWidget {
  final ReportsProvider reportsProvider;

  const _FinancialReportContent({required this.reportsProvider});

  void _handleDateRangeChanged(
    BuildContext context,
    DateTime start,
    DateTime end,
  ) {
    reportsProvider.setDateRange(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filters section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ReportFilters(
            onDateRangeChanged:
                (start, end) => _handleDateRangeChanged(context, start, end),
            onPropertyFilterChanged: (selectedProps) {
              log.info('Property filter changed (not implemented for simplified report): $selectedProps');
            },
          ),
        ),

        const SizedBox(height: 16),

        // Report data table section
        Expanded(
          child: Builder(
            builder: (context) {
              if (reportsProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (reportsProvider.error != null) {
                return Center(child: Text('Error: ${reportsProvider.error}'));
              }
              if (reportsProvider.financialReports.isEmpty) {
                return const Center(child: Text('No financial data found for the selected period.'));
              }

              final List<DataColumn> columns = [
                const DataColumn(label: Text('Date From')),
                const DataColumn(label: Text('Date To')),
                const DataColumn(label: Text('Property')),
                const DataColumn(label: Text('Total Rent')),
                const DataColumn(label: Text('Maintenance Costs')),
                const DataColumn(label: Text('Net Total')),
              ];

              final List<DataRow> rows = reportsProvider.financialReports.map((item) {
                return DataRow(cells: [
                  DataCell(Text(item['dateFrom']?.toString().split('T')[0] ?? 'N/A')),
                  DataCell(Text(item['dateTo']?.toString().split('T')[0] ?? 'N/A')),
                  DataCell(Text(item['property'] ?? 'N/A')),
                  DataCell(Text(item['totalRent']?.toStringAsFixed(2) ?? '0.00')),
                  DataCell(Text(item['maintenanceCosts']?.toStringAsFixed(2) ?? '0.00')),
                  DataCell(Text(item['total']?.toStringAsFixed(2) ?? '0.00')),
                ]);
              }).toList();

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: columns,
                  rows: rows,
                  headingRowColor: MaterialStateProperty.resolveWith((states) => Colors.grey[200]),
                  dataRowColor: MaterialStateProperty.resolveWith((states) => Colors.white),
                  columnSpacing: 24,
                  horizontalMargin: 24,
                  border: TableBorder.all(color: Colors.grey[300]!),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
