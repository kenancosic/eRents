import 'package:e_rents_desktop/features/reports/providers/base_report_provider.dart';
import 'package:e_rents_desktop/models/reports/tenant_report_item.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'dart:convert';

class TenantReportProvider extends BaseReportProvider<TenantReportItem> {
  // String? _reportTitle; // Now in BaseReportProvider via getReportTitle()
  // String? _reportPeriod; // Similarly derived
  // DateTime? _startDate; // Now in BaseReportProvider
  // DateTime? _endDate; // Now in BaseReportProvider

  TenantReportProvider(ApiService? apiService) : super(apiService: apiService);

  // String? get reportTitle => _reportTitle; // Redundant
  // String? get reportPeriod => _reportPeriod; // Redundant

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
    // TODO: Replace with proper mock data structure
    return [];
  }

  // This method is required by BaseReportProvider
  @override
  String getReportName() => 'Tenant Report';

  @override
  Future<List<TenantReportItem>> fetchReportData() async {
    if (isMockDataEnabled) {
      return getMockItems();
    }
    if (apiService == null) {
      print("TenantReportProvider: ApiService is null. Cannot fetch data.");
      throw Exception("ApiService not available for TenantReportProvider");
    }

    String urlWithParams = endpoint;
    final queryParamsMap = {
      'startDate': dateFormat.format(startDate),
      'endDate': dateFormat.format(endDate),
    };

    if (queryParamsMap.isNotEmpty) {
      final queryString = Uri(queryParameters: queryParamsMap).query;
      urlWithParams = '$urlWithParams?$queryString';
    }

    try {
      final response = await apiService!.get(urlWithParams);
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((itemJson) => fromJson(itemJson)).toList();
    } catch (e) {
      print(
        'TenantReportProvider.fetchReportData error for URL $urlWithParams: $e',
      );
      throw Exception('Failed to fetch tenant report data: $e');
    }
  }

  /// Generate tenant report for date range
  Future<void> generateReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // _startDate = startDate; // Handled by BaseReportProvider
    // _endDate = endDate; // Handled by BaseReportProvider
    // _reportTitle = 'Tenant Report'; // Handled by BaseReportProvider
    // _reportPeriod = // Handled by BaseReportProvider
    //     '${startDate.toString().substring(0, 10)} - ${endDate.toString().substring(0, 10)}';

    // await fetchItems(); // fetchItems is automatically called by setDateRange if data not cached
    setDateRange(
      startDate,
      endDate,
    ); // This will trigger onDateRangeChanged -> fetchItems
  }
}
