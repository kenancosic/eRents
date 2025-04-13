import 'package:e_rents_desktop/features/reports/providers/base_report_provider.dart';
import 'package:e_rents_desktop/models/reports/occupancy_report_item.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';

class OccupancyReportProvider extends BaseReportProvider<OccupancyReportItem> {
  @override
  String get endpoint => 'api/reports/occupancy';

  @override
  OccupancyReportItem fromJson(Map<String, dynamic> json) {
    return OccupancyReportItem.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(OccupancyReportItem item) {
    return item.toJson();
  }

  @override
  List<OccupancyReportItem> getMockItems() {
    return MockDataService.getMockOccupancyReportData();
  }

  @override
  void onDateRangeChanged() {
    // For occupancy reports, we don't need to refresh data on date changes
    // since the current snapshot is shown regardless of dates
    notifyListeners();
  }

  @override
  String getReportName() {
    return 'Occupancy Report';
  }
}
