import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class ExportService {
  // Get a valid export directory
  static Future<String> _getExportDirectory() async {
    try {
      // Try to get downloads directory first
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        return downloads.path;
      }

      // Fallback to application documents directory
      final documents = await getApplicationDocumentsDirectory();
      final exportDir = Directory(path.join(documents.path, 'exports'));

      // Create the exports directory if it doesn't exist
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      return exportDir.path;
    } catch (e) {
      debugPrint('Error getting export directory: $e');
      // Last resort: use temp directory
      final temp = await getTemporaryDirectory();
      return temp.path;
    }
  }

  // Sanitize filename to be valid across platforms
  static String _sanitizeFileName(String fileName) {
    // Remove invalid characters
    final sanitized = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    // Limit length to avoid path length issues
    return sanitized.length > 100 ? sanitized.substring(0, 100) : sanitized;
  }

  // Create a valid file path for export
  static Future<String> _createExportFilePath(
    String title,
    String extension,
  ) async {
    final directory = await _getExportDirectory();
    final sanitizedTitle = _sanitizeFileName(title);
    final filePath = path.join(directory, '$sanitizedTitle.$extension');

    // Handle file name conflicts by adding a number
    var finalPath = filePath;
    var counter = 1;
    while (await File(finalPath).exists()) {
      final newName = '$sanitizedTitle ($counter).$extension';
      finalPath = path.join(directory, newName);
      counter++;
    }

    return finalPath;
  }

  // Open a file with the system's default application
  static Future<bool> openFile(String filePath) async {
    try {
      if (Platform.isWindows) {
        // Use explorer.exe to open the file with default application
        final result = await Process.run('explorer.exe', [filePath]);
        if (result.exitCode != 0) {
          debugPrint('Error opening file: ${result.stderr}');
          return false;
        }
        return true;
      } else {
        // For other platforms, try using url_launcher
        final uri = Uri.file(filePath);
        if (await url_launcher.canLaunchUrl(uri)) {
          await url_launcher.launchUrl(uri);
          return true;
        }
      }
      debugPrint('Cannot launch file: $filePath');
      return false;
    } catch (e) {
      debugPrint('Error opening file: $e');
      return false;
    }
  }

  static Future<String> exportToPDF({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    bool openAfterExport = true,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text(title)),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: rows,
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.center,
                cellStyle: const pw.TextStyle(),
              ),
            ],
          );
        },
      ),
    );

    final filePath = await _createExportFilePath(title, 'pdf');
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    if (openAfterExport) {
      await openFile(filePath);
    }

    return file.path;
  }

  static Future<String> exportToExcel({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    bool openAfterExport = true,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!];

    // Add headers
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add data rows
    for (var i = 0; i < rows.length; i++) {
      for (var j = 0; j < rows[i].length; j++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1),
        );
        cell.value = TextCellValue(rows[i][j]);
        cell.cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Center);
      }
    }

    final filePath = await _createExportFilePath(title, 'xlsx');
    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    if (openAfterExport) {
      await openFile(filePath);
    }

    return file.path;
  }

  static Future<String> exportToCSV({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    bool openAfterExport = true,
  }) async {
    final csvData = [headers, ...rows];
    final csvString = const ListToCsvConverter().convert(csvData);

    final filePath = await _createExportFilePath(title, 'csv');
    final file = File(filePath);
    await file.writeAsString(csvString);

    if (openAfterExport) {
      await openFile(filePath);
    }

    return file.path;
  }
}
