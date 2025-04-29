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
    return Row(
      children: [
        _buildExportButton(
          context,
          'PDF',
          Icons.picture_as_pdf_outlined,
          Colors.red.shade700,
          onExportPDF,
        ),
        const SizedBox(width: 8),
        _buildExportButton(
          context,
          'Excel',
          Icons.table_chart_outlined,
          Colors.green.shade700,
          onExportExcel,
        ),
        const SizedBox(width: 8),
        _buildExportButton(
          context,
          'CSV',
          Icons.description_outlined,
          Colors.blue.shade700,
          onExportCSV,
        ),
      ],
    );
  }

  Widget _buildExportButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
