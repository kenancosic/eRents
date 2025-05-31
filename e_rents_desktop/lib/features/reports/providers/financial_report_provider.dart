import 'package:e_rents_desktop/features/reports/providers/base_report_provider.dart';
import 'package:e_rents_desktop/models/reports/financial_report_item.dart';
import 'package:e_rents_desktop/services/report_service.dart';

class FinancialReportProvider extends BaseReportProvider<FinancialReportItem> {
  final ReportService? _reportService;

  FinancialReportProvider(this._reportService) : super();

  @override
  String get endpoint => '/reports/financial';

  @override
  FinancialReportItem fromJson(Map<String, dynamic> json) {
    return FinancialReportItem.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(FinancialReportItem item) {
    return item.toJson();
  }

  @override
  List<FinancialReportItem> getMockItems() {
    return [];
  }

  @override
  String getReportName() => 'Financial Report';

  @override
  Future<List<FinancialReportItem>> fetchReportData() async {
    if (isMockDataEnabled) {
      return getMockItems();
    }

    if (_reportService == null) {
      throw Exception(
        "ReportService not available for FinancialReportProvider",
      );
    }

    try {
      print('FinancialReportProvider: Fetching financial report data...');
      final reportItems = await _reportService!.getFinancialReport(
        startDate,
        endDate,
      );
      print(
        'FinancialReportProvider: Successfully fetched ${reportItems.length} financial report items.',
      );
      return reportItems;
    } catch (e) {
      print(
        'FinancialReportProvider: Error fetching financial report data: $e',
      );
      throw Exception('Failed to fetch financial report data: $e');
    }
  }

  Future<void> generateReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    setDateRange(startDate, endDate);
  }
}
