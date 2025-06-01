import 'dart:convert';
import 'package:e_rents_desktop/models/reports/financial_report_item.dart';
import 'package:e_rents_desktop/models/reports/tenant_report_item.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

// TODO: Full backend integration for all report features is pending.
// Ensure all endpoints are functional and error handling is robust.
class ReportService extends ApiService {
  ReportService(String baseUrl, SecureStorageService secureStorageService)
    : super(baseUrl, secureStorageService);

  Future<List<FinancialReportItem>> getFinancialReport(
    DateTime startDate,
    DateTime endDate,
  ) async {
    debugPrint('ReportService: Attempting to fetch financial report...');
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String formattedStartDate = formatter.format(startDate);
    final String formattedEndDate = formatter.format(endDate);

    final endpoint =
        '/reports/financial?startDate=$formattedStartDate&endDate=$formattedEndDate';

    debugPrint('ReportService: Calling endpoint: $endpoint');

    try {
      final response = await get(
        endpoint,
        authenticated: true,
      ); // Assuming reports need auth

      debugPrint('ReportService: Response status: ${response.statusCode}');
      debugPrint('ReportService: Response body: ${response.body}');

      final decodedResponse = json.decode(response.body);
      // Add individual item parsing try-catch if needed
      final reportItems =
          (decodedResponse as List)
              .map((item) => FinancialReportItem.fromJson(item))
              .toList();
      debugPrint(
        'ReportService: Successfully fetched ${reportItems.length} financial report items.',
      );
      return reportItems;
    } catch (e) {
      debugPrint(
        'ReportService: Error fetching financial report: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to fetch financial report. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<List<TenantReportItem>> getTenantReport(
    DateTime startDate,
    DateTime endDate,
  ) async {
    debugPrint('ReportService: Attempting to fetch tenant report...');
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String formattedStartDate = formatter.format(startDate);
    final String formattedEndDate = formatter.format(endDate);

    final endpoint =
        '/reports/tenant?startDate=$formattedStartDate&endDate=$formattedEndDate';

    debugPrint('ReportService: Calling endpoint: $endpoint');

    try {
      final response = await get(
        endpoint,
        authenticated: true,
      ); // Assuming reports need auth

      debugPrint('ReportService: Response status: ${response.statusCode}');
      debugPrint('ReportService: Response body: ${response.body}');

      final decodedResponse = json.decode(response.body);
      // Add individual item parsing try-catch if needed
      final reportItems =
          (decodedResponse as List)
              .map((item) => TenantReportItem.fromJson(item))
              .toList();
      debugPrint(
        'ReportService: Successfully fetched ${reportItems.length} tenant report items.',
      );
      return reportItems;
    } catch (e) {
      debugPrint(
        'ReportService: Error fetching tenant report: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to fetch tenant report. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }
}
