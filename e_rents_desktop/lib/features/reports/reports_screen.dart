import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/reports/widgets/report_table.dart';
import 'package:e_rents_desktop/features/reports/widgets/report_filters.dart';
import 'package:e_rents_desktop/features/reports/widgets/export_options.dart';
import 'package:e_rents_desktop/features/reports/providers/reports_provider.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:flutter/services.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    // Load reports data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticatedState) {
        final reportsProvider = Provider.of<ReportsProvider>(
          context,
          listen: false,
        );
        reportsProvider.loadCurrentReportData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ReportsProvider, AuthProvider>(
      builder: (context, reportsProvider, authProvider, _) {
        // If not authenticated, show login prompt
        if (!authProvider.isAuthenticatedState) {
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

        return _ReportsScreenContent(reportsProvider: reportsProvider);
      },
    );
  }
}

class _ReportsScreenContent extends StatelessWidget {
  final ReportsProvider reportsProvider;

  const _ReportsScreenContent({required this.reportsProvider});

  void _showExportResult(
    BuildContext context,
    String filePath,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  Text(
                    'Saved to: $filePath',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: filePath));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Path copied to clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: const Text('Copy Path'),
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Export failed: $error')),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleExportPDF(BuildContext context) async {
    try {
      final filePath = await reportsProvider.exportToPDF();
      if (!context.mounted) return;

      _showExportResult(
        context,
        filePath,
        'PDF file exported and opened with system viewer',
      );
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, e.toString());
    }
  }

  Future<void> _handleExportExcel(BuildContext context) async {
    try {
      final filePath = await reportsProvider.exportToExcel();
      if (!context.mounted) return;

      _showExportResult(
        context,
        filePath,
        'Excel file exported and opened with system viewer',
      );
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, e.toString());
    }
  }

  Future<void> _handleExportCSV(BuildContext context) async {
    try {
      final filePath = await reportsProvider.exportToCSV();
      if (!context.mounted) return;

      _showExportResult(
        context,
        filePath,
        'CSV file exported and opened with system viewer',
      );
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, e.toString());
    }
  }

  void _handleDateRangeChanged(
    BuildContext context,
    DateTime start,
    DateTime end,
  ) {
    reportsProvider.setDateRange(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> reportTypes = ["Financial Report", "Tenant Report"];

    return Column(
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
                color: Colors.black.withAlpha(13), // 0.05 opacity
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
                  value: reportsProvider.getReportTypeString(),
                  items:
                      reportTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      reportsProvider.setReportTypeFromString(newValue);
                      reportsProvider.loadCurrentReportData();
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
          onDateRangeChanged:
              (start, end) => _handleDateRangeChanged(context, start, end),
          onPropertyFilterChanged: (selectedProps) {
            // TODO: Implement property filter logic if needed by reports
            print('Property filter changed: $selectedProps');
          },
        ),

        const SizedBox(height: 16),

        // Report data table section
        const Expanded(child: ReportTable()),
      ],
    );
  }
}
