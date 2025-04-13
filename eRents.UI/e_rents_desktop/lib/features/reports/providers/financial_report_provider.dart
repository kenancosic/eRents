import 'package:e_rents_desktop/features/reports/providers/base_report_provider.dart';
import 'package:e_rents_desktop/models/reports/financial_report_item.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';

class FinancialReportProvider extends BaseReportProvider<FinancialReportItem> {
  @override
  String get endpoint => 'api/reports/financial';

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
  String getReportName() {
    return 'Financial Report';
  }
}
