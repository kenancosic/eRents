import 'package:e_rents_desktop/features/reports/providers/base_report_provider.dart';
import 'package:e_rents_desktop/models/reports/tenant_report_item.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';
import 'package:e_rents_desktop/services/report_service.dart';
import 'package:flutter/foundation.dart';

class TenantReportProvider extends BaseReportProvider<TenantReportItem> {
  final ReportService _reportService;

  TenantReportProvider({required ReportService reportService})
    : _reportService = reportService,
      super();

  @override
  String get endpoint => '/reports/tenants';

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
    return MockDataService.getMockTenantReportData();
  }

  @override
  String getReportName() => 'Tenant Report';

  @override
  Future<List<TenantReportItem>> fetchReportData() async {
    if (isMockDataEnabled) {
      if (kDebugMode) {
        print('TenantReportProvider: Using mock data.');
      }
      return getMockItems();
    } else {
      if (kDebugMode) {
        print('TenantReportProvider: Fetching real data.');
      }
      return await _reportService.getTenantReport(startDate, endDate);
    }
  }

  @override
  void onDateRangeChanged() {
    if (!isMockDataEnabled) {
      debugPrint(
        "TenantReportProvider.onDateRangeChanged: Fetching new data due to date change and real data mode.",
      );
      fetchItems();
    } else {
      debugPrint(
        "TenantReportProvider.onDateRangeChanged: Using mock data, no refetch needed on date change.",
      );
      notifyListeners();
    }
  }

  // Count of leases ending soon (within 30 days)
  int get leasesEndingSoonCount =>
      items
          .where((item) => item.daysRemaining > 0 && item.daysRemaining <= 30)
          .length;

  // Calculate average rent
  double get averageRent {
    if (items.isEmpty) return 0;
    return items.fold(0.0, (sum, item) => sum + item.costOfRent) / items.length;
  }
}
