import 'package:flutter/material.dart';

class ExportOptions extends StatelessWidget {
  final VoidCallback onExportPDF;
  final VoidCallback onExportExcel;
  final VoidCallback onExportCSV;

  const ExportOptions({
    super.key,
    required this.onExportPDF,
    required this.onExportExcel,
    required this.onExportCSV,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.download),
      tooltip: 'Export Report',
      itemBuilder:
          (context) => [
            const PopupMenuItem(
              value: 'pdf',
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Export as PDF'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'excel',
              child: Row(
                children: [
                  Icon(Icons.table_chart, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Export as Excel'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'csv',
              child: Row(
                children: [
                  Icon(Icons.description, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Export as CSV'),
                ],
              ),
            ),
          ],
      onSelected: (value) {
        switch (value) {
          case 'pdf':
            onExportPDF();
            break;
          case 'excel':
            onExportExcel();
            break;
          case 'csv':
            onExportCSV();
            break;
        }
      },
    );
  }
}
