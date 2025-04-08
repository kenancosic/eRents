import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/features/reports/widgets/report_table.dart';
import 'package:e_rents_desktop/features/reports/widgets/report_filters.dart';
import 'package:e_rents_desktop/features/reports/widgets/export_options.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedReportType = 'Financial Report';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  final List<String> _reportTypes = [
    'Financial Report',
    'Occupancy Report',
    'Maintenance Report',
    'Tenant Report',
  ];

  void _handleDateRangeChanged(DateTime start, DateTime end) {
    setState(() {
      _startDate = start;
      _endDate = end;
    });
  }

  void _handleExportPDF() {
    // TODO: Implement PDF export
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Exporting as PDF...')));
  }

  void _handleExportExcel() {
    // TODO: Implement Excel export
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Exporting as Excel...')));
  }

  void _handleExportCSV() {
    // TODO: Implement CSV export
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Exporting as CSV...')));
  }

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title: 'Reports',
      currentPath: '/reports',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DropdownButton<String>(
                value: _selectedReportType,
                items:
                    _reportTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedReportType = newValue;
                    });
                  }
                },
              ),
              const Spacer(),
              ExportOptions(
                onExportPDF: _handleExportPDF,
                onExportExcel: _handleExportExcel,
                onExportCSV: _handleExportCSV,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ReportFilters(
            startDate: _startDate,
            endDate: _endDate,
            onDateRangeChanged: _handleDateRangeChanged,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ReportTable(
              reportType: _selectedReportType,
              startDate: _startDate,
              endDate: _endDate,
            ),
          ),
        ],
      ),
    );
  }
}
