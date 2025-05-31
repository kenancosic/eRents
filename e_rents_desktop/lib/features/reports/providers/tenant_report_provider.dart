import 'package:e_rents_desktop/features/reports/providers/base_report_provider.dart';
import 'package:e_rents_desktop/models/reports/tenant_report_item.dart';
import 'package:e_rents_desktop/services/report_service.dart';

class TenantReportProvider extends BaseReportProvider<TenantReportItem> {
  final ReportService? _reportService;

  TenantReportProvider(this._reportService) : super();

  @override
  String get endpoint => '/reports/tenant';

  @override
  TenantReportItem fromJson(Map<String, dynamic> json) {
    return TenantReportItem.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(TenantReportItem item) {
    return item.toJson();
  }

  @override
  List<TenantReportItem> getMockItems() {
    return [];
  }

  @override
  String getReportName() => 'Tenant Report';

  @override
  Future<List<TenantReportItem>> fetchReportData() async {
    if (isMockDataEnabled) {
      return getMockItems();
    }

    if (_reportService == null) {
      throw Exception("ReportService not available for TenantReportProvider");
    }

    try {
      print('TenantReportProvider: Fetching tenant report data...');
      final reportItems = await _reportService!.getTenantReport(
        startDate,
        endDate,
      );
      print(
        'TenantReportProvider: Successfully fetched ${reportItems.length} tenant report items.',
      );
      return reportItems;
    } catch (e) {
      print('TenantReportProvider: Error fetching tenant report data: $e');
      throw Exception('Failed to fetch tenant report data: $e');
    }
  }

  /// Generate tenant report for date range
  Future<void> generateReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    setDateRange(startDate, endDate);
  }
}
