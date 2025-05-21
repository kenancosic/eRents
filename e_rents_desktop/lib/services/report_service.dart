import 'dart:convert';
import 'package:e_rents_desktop/models/reports/financial_report_item.dart';
import 'package:e_rents_desktop/models/reports/tenant_report_item.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';
import 'package:intl/intl.dart';

class ReportService extends ApiService {
  ReportService(String baseUrl, SecureStorageService secureStorageService)
    : super(baseUrl, secureStorageService);

  Future<List<FinancialReportItem>> getFinancialReport(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String formattedStartDate = formatter.format(startDate);
    final String formattedEndDate = formatter.format(endDate);

    final endpoint =
        '/reports/financial?startDate=$formattedStartDate&endDate=$formattedEndDate';
    final response = await get(endpoint);

    final decodedResponse = json.decode(response.body);

    return (decodedResponse as List)
        .map((item) => FinancialReportItem.fromJson(item))
        .toList();
  }

  Future<List<TenantReportItem>> getTenantReport(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String formattedStartDate = formatter.format(startDate);
    final String formattedEndDate = formatter.format(endDate);

    final endpoint =
        '/reports/tenant?startDate=$formattedStartDate&endDate=$formattedEndDate';
    final response = await get(endpoint);

    final decodedResponse = json.decode(response.body);

    return (decodedResponse as List)
        .map((item) => TenantReportItem.fromJson(item))
        .toList();
  }
}
