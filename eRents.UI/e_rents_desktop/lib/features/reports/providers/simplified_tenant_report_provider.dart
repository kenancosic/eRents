import 'package:e_rents_desktop/features/reports/providers/base_report_provider.dart';
import 'package:e_rents_desktop/models/reports/tenant_report_item.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';
import 'package:flutter/foundation.dart';

class TenantReportProvider extends BaseReportProvider<TenantReportItem> {
  @override
  String get endpoint => 'api/reports/tenants';

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
    debugPrint(
      'TenantReportProvider: Fetching data for date range ${formattedStartDate} - ${formattedEndDate}',
    );
    return MockDataService.getMockTenantReportData();
  }

  @override
  void onDateRangeChanged() {
    // For tenant reports, we don't need to refresh data on date changes
    // since we show all tenants regardless of dates
    notifyListeners();
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
