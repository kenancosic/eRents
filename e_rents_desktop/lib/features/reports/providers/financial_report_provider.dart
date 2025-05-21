import 'package:e_rents_desktop/features/reports/providers/base_report_provider.dart';
import 'package:e_rents_desktop/models/reports/financial_report_item.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';
import 'package:e_rents_desktop/services/report_service.dart';
import 'package:flutter/foundation.dart';

class FinancialReportProvider extends BaseReportProvider<FinancialReportItem> {
  final ReportService _reportService;

  FinancialReportProvider({required ReportService reportService})
    : _reportService = reportService,
      super();

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
    return MockDataService.getMockFinancialReportData(startDate, endDate);
  }

  @override
  String getReportName() => 'Financial Report';

  @override
  Future<List<FinancialReportItem>> fetchReportData() async {
    if (isMockDataEnabled) {
      if (kDebugMode) {
        print(
          'FinancialReportProvider: Using mock data for date range $startDateFormatted - $endDateFormatted',
        );
      }
      return getMockItems();
    } else {
      if (kDebugMode) {
        print(
          'FinancialReportProvider: Fetching real data for date range $startDateFormatted - $endDateFormatted',
        );
      }
      return await _reportService.getFinancialReport(startDate, endDate);
    }
  }
}
