import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/features/reports/widgets/report_table.dart';
import 'package:e_rents_desktop/features/reports/widgets/report_filters.dart';
import 'package:e_rents_desktop/features/reports/widgets/export_options.dart';
import 'package:e_rents_desktop/features/reports/providers/reports_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportsProvider(),
      child: const _ReportsScreenContent(),
    );
  }
}

class _ReportsScreenContent extends StatelessWidget {
  const _ReportsScreenContent();

  void _handleDateRangeChanged(
    BuildContext context,
    DateTime start,
    DateTime end,
  ) {
    final provider = Provider.of<ReportsProvider>(context, listen: false);
    provider.setDateRange(start, end);
  }

  void _handleExportPDF(BuildContext context) {
    final provider = Provider.of<ReportsProvider>(context, listen: false);
    provider.exportToPDF();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting as PDF...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleExportExcel(BuildContext context) {
    final provider = Provider.of<ReportsProvider>(context, listen: false);
    provider.exportToExcel();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting as Excel...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleExportCSV(BuildContext context) {
    final provider = Provider.of<ReportsProvider>(context, listen: false);
    provider.exportToCSV();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting as CSV...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReportsProvider>(context);
    final List<String> reportTypes = [
      'Financial Report',
      'Occupancy Report',
      'Maintenance Report',
      'Tenant Report',
    ];

    return AppBaseScreen(
      title: 'Reports',
      currentPath: '/reports',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section with title and report type selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                const Text(
                  'Report Type:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    value: provider.getReportTypeString(),
                    items:
                        reportTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        provider.setReportTypeFromString(newValue);
                      }
                    },
                  ),
                ),
                const Spacer(),
                ExportOptions(
                  onExportPDF: () => _handleExportPDF(context),
                  onExportExcel: () => _handleExportExcel(context),
                  onExportCSV: () => _handleExportCSV(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Filters section
          ReportFilters(
            startDate: provider.startDate,
            endDate: provider.endDate,
            onDateRangeChanged:
                (start, end) => _handleDateRangeChanged(context, start, end),
          ),

          const SizedBox(height: 16),

          // Report data table section
          const Expanded(child: ReportTable()),
        ],
      ),
    );
  }
}
