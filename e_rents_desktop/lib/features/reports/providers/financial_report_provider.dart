import 'package:e_rents_desktop/features/reports/providers/base_report_provider.dart';
import 'package:e_rents_desktop/models/reports/financial_report_item.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'dart:convert'; // Required for json.decode

class FinancialReportProvider extends BaseReportProvider<FinancialReportItem> {
  // String? _reportTitle; // Redundant
  // String? _reportPeriod; // Redundant

  FinancialReportProvider(ApiService? apiService)
    : super(apiService: apiService);

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

    if (apiService == null) {
      print("FinancialReportProvider: ApiService is null. Cannot fetch data.");
      throw Exception("ApiService not available for FinancialReportProvider");
    }

    String urlWithParams = endpoint;
    final queryParamsMap = {
      'startDate': dateFormat.format(startDate),
      'endDate': dateFormat.format(endDate),
    };

    // Uri.https will handle proper encoding
    // Assuming your apiService.baseUrl is something like "example.com" and endpoint is "/path"
    // And apiService.get handles adding the base URL. For now, just append to endpoint.
    if (queryParamsMap.isNotEmpty) {
      final queryString = Uri(queryParameters: queryParamsMap).query;
      urlWithParams = '$urlWithParams?$queryString';
    }

    try {
      // Assuming apiService.get takes the full path with query string
      // And handles authentication internally based on a global setting or token
      final response = await apiService!.get(urlWithParams);
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((itemJson) => fromJson(itemJson)).toList();
    } catch (e) {
      print(
        'FinancialReportProvider.fetchReportData error for URL $urlWithParams: $e',
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
