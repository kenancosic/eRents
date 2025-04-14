import 'package:e_rents_desktop/features/reports/providers/base_report_provider.dart';
import 'package:e_rents_desktop/models/reports/maintenance_report_item.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';
import 'package:flutter/foundation.dart';

class MaintenanceReportProvider
    extends BaseReportProvider<MaintenanceReportItem> {
  @override
  String get endpoint => 'api/reports/maintenance';

  @override
  MaintenanceReportItem fromJson(Map<String, dynamic> json) {
    return MaintenanceReportItem.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(MaintenanceReportItem item) {
    return item.toJson();
  }

  @override
  String getReportName() => 'Maintenance Report';

  @override
  Future<List<MaintenanceReportItem>> fetchReportData() async {
    debugPrint(
      'MaintenanceReportProvider: Fetching data for date range ${formattedStartDate} - ${formattedEndDate}',
    );
    return MockDataService.getMockMaintenanceReportData(startDate, endDate);
  }

  @override
  List<MaintenanceReportItem> getMockItems() {
    return MockDataService.getMockMaintenanceReportData(startDate, endDate);
  }

  // Get counts by priority
  int get highPriorityCount =>
      items.where((item) => item.priority == MaintenancePriority.high).length;
  int get mediumPriorityCount =>
      items.where((item) => item.priority == MaintenancePriority.medium).length;
  int get lowPriorityCount =>
      items.where((item) => item.priority == MaintenancePriority.low).length;

  // Get counts by status
  int getCountByStatus(String status) {
    return items
        .where((item) => item.status.toLowerCase() == status.toLowerCase())
        .length;
  }

  // Calculate total cost of maintenance
  double get totalCost => items.fold(0, (sum, item) => sum + item.cost);
}
