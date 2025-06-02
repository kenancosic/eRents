import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/reports/providers/reports_state_provider.dart';
import 'package:e_rents_desktop/features/reports/widgets/financial_report_table.dart';
import 'package:e_rents_desktop/features/reports/widgets/tenant_report_table.dart';

class ReportTable extends StatelessWidget {
  const ReportTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsStateProvider>(
      builder: (context, reportsProvider, child) {
        debugPrint(
          'ReportTable.build: Current report type: ${reportsProvider.currentReportType}',
        );

        // Handle loading state
        if (reportsProvider.isLoading) {
          debugPrint('ReportTable: Showing loading state');
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading data...'),
              ],
            ),
          );
        }

        // Handle error state
        if (reportsProvider.error != null) {
          debugPrint('ReportTable: Showing error state');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading data: ${reportsProvider.error?.message ?? "Unknown error"}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  onPressed: () {
                    debugPrint('Retry button pressed');
                    reportsProvider.loadCurrentReportData(forceRefresh: true);
                  },
                ),
              ],
            ),
          );
        }

        // Handle empty data state
        final currentData = reportsProvider.currentReportData;
        if (currentData == null || currentData.isEmpty) {
          debugPrint('ReportTable: Showing empty state');
          final message =
              reportsProvider.currentReportType == ReportType.financial
                  ? 'No financial data available for the selected period'
                  : 'No tenant data available for the selected period';

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_open, color: Colors.grey, size: 48),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  onPressed: () {
                    debugPrint('Refresh button pressed');
                    reportsProvider.loadCurrentReportData(forceRefresh: true);
                  },
                ),
              ],
            ),
          );
        }

        // Show the appropriate table based on report type
        debugPrint(
          'ReportTable: Showing table with ${currentData.length} items',
        );

        switch (reportsProvider.currentReportType) {
          case ReportType.financial:
            return const FinancialReportTable();
          case ReportType.tenant:
            return const TenantReportTable();
        }
      },
    );
  }
}
