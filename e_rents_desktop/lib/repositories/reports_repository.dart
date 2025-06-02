import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/base/base.dart';
import 'package:e_rents_desktop/models/reports/financial_report_item.dart';
import 'package:e_rents_desktop/models/reports/tenant_report_item.dart';
import 'package:e_rents_desktop/services/report_service.dart';
import 'package:intl/intl.dart';

/// Repository for reports data management with intelligent caching
/// Handles financial reports, tenant reports, and related analytics
class ReportsRepository {
  final ReportService service;
  final CacheManager cacheManager;

  // Cache TTL configurations
  static const Duration _reportCacheTtl = Duration(minutes: 10);

  ReportsRepository({required this.service, required this.cacheManager});

  /// Load financial report data with caching
  /// Returns financial metrics and transactions for the specified date range
  Future<List<FinancialReportItem>> getFinancialReport({
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    final effectiveStartDate =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final effectiveEndDate = endDate ?? DateTime.now();

    final cacheKey =
        'reports_financial_${_formatDate(effectiveStartDate)}_${_formatDate(effectiveEndDate)}';

    if (!forceRefresh) {
      final cached = await cacheManager.get<List<FinancialReportItem>>(
        cacheKey,
      );
      if (cached != null) {
        debugPrint(
          'ReportsRepository: Returning cached financial report with ${cached.length} items',
        );
        return cached;
      }
    }

    try {
      debugPrint('ReportsRepository: Fetching fresh financial report data...');
      final reportData = await service.getFinancialReport(
        effectiveStartDate,
        effectiveEndDate,
      );

      // Cache with 10-minute TTL for report data
      await cacheManager.set(cacheKey, reportData, duration: _reportCacheTtl);
      debugPrint(
        'ReportsRepository: Financial report cached successfully with ${reportData.length} items',
      );

      return reportData;
    } catch (e, stackTrace) {
      debugPrint('ReportsRepository: Error loading financial report: $e');
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Load tenant report data with caching
  /// Returns tenant metrics and activity for the specified date range
  Future<List<TenantReportItem>> getTenantReport({
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    final effectiveStartDate =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final effectiveEndDate = endDate ?? DateTime.now();

    final cacheKey =
        'reports_tenant_${_formatDate(effectiveStartDate)}_${_formatDate(effectiveEndDate)}';

    if (!forceRefresh) {
      final cached = await cacheManager.get<List<TenantReportItem>>(cacheKey);
      if (cached != null) {
        debugPrint(
          'ReportsRepository: Returning cached tenant report with ${cached.length} items',
        );
        return cached;
      }
    }

    try {
      debugPrint('ReportsRepository: Fetching fresh tenant report data...');
      final reportData = await service.getTenantReport(
        effectiveStartDate,
        effectiveEndDate,
      );

      // Cache with 10-minute TTL for report data
      await cacheManager.set(cacheKey, reportData, duration: _reportCacheTtl);
      debugPrint(
        'ReportsRepository: Tenant report cached successfully with ${reportData.length} items',
      );

      return reportData;
    } catch (e, stackTrace) {
      debugPrint('ReportsRepository: Error loading tenant report: $e');
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Get formatted financial report data for export
  /// Returns headers and rows that can be used with ExportService
  Map<String, dynamic> getFinancialReportExportData(
    List<FinancialReportItem> data,
    DateTime startDate,
    DateTime endDate,
  ) {
    final headers = [
      'Date From',
      'Date To',
      'Property',
      'Total Rent',
      'Maintenance Costs',
      'Net Total',
    ];

    final rows =
        data
            .map(
              (item) => [
                item.dateFrom,
                item.dateTo,
                item.property,
                item.totalRent.toString(),
                item.maintenanceCosts.toString(),
                item.total.toString(),
              ],
            )
            .toList();

    final title =
        'Financial Report (${_formatDate(startDate)} to ${_formatDate(endDate)})';

    return {'title': title, 'headers': headers, 'rows': rows};
  }

  /// Get formatted tenant report data for export
  /// Returns headers and rows that can be used with ExportService
  Map<String, dynamic> getTenantReportExportData(
    List<TenantReportItem> data,
    DateTime startDate,
    DateTime endDate,
  ) {
    final headers = [
      'Tenant Name',
      'Property',
      'Cost of Rent',
      'Total Paid Rent',
      'Start Date',
      'End Date',
    ];

    final rows =
        data
            .map(
              (item) => [
                item.tenantName,
                item.propertyName,
                item.costOfRent.toString(),
                item.totalPaidRent.toString(),
                item.dateFrom,
                item.dateTo,
              ],
            )
            .toList();

    final title =
        'Tenant Report (${_formatDate(startDate)} to ${_formatDate(endDate)})';

    return {'title': title, 'headers': headers, 'rows': rows};
  }

  /// Format date for cache keys and API calls
  String _formatDate(DateTime date) {
    final formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(date);
  }

  /// Clear all reports caches
  Future<void> clearCache() async {
    await cacheManager.clear('reports_financial');
    await cacheManager.clear('reports_tenant');
    debugPrint('ReportsRepository: Cache cleared');
  }
}
