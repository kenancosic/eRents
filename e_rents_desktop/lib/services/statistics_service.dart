import 'dart:convert';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/models/statistics/property_statistics.dart';
import 'package:e_rents_desktop/models/statistics/maintenance_statistics.dart';
import 'package:e_rents_desktop/models/statistics/dashboard_statistics.dart';
import 'package:e_rents_desktop/models/statistics/financial_summary_dto.dart';
import 'package:e_rents_desktop/models/statistics/financial_statistics_api.dart';

class StatisticsService extends ApiService {
  StatisticsService(super.baseUrl, super.secureStorageService);

  /// Get dashboard statistics for the authenticated landlord
  /// Returns overview of portfolio including occupancy, revenue, top properties, etc.
  Future<DashboardStatistics> getDashboardStatistics() async {
    try {
      print('StatisticsService: Fetching dashboard statistics...');

      final response = await get('/Statistics/dashboard', authenticated: true);

      final statistics = DashboardStatistics.fromJson(
        jsonDecode(response.body),
      );

      print(
        'StatisticsService: Successfully fetched dashboard statistics. Total Properties: ${statistics.totalProperties}',
      );

      return statistics;
    } catch (e) {
      print('StatisticsService: Error fetching dashboard statistics: $e');
      rethrow;
    }
  }

  /// Get property statistics
  /// Returns detailed statistics about property performance
  Future<PropertyStatistics> getPropertyStatistics() async {
    try {
      print('StatisticsService: Fetching property statistics...');

      final response = await get('/Statistics/properties', authenticated: true);

      final PropertyStatistics properties = PropertyStatistics.fromJson(
        jsonDecode(response.body),
      );

      print('StatisticsService: Successfully fetched property statistics.');

      return properties;
    } catch (e) {
      print('StatisticsService: Error fetching property statistics: $e');
      rethrow;
    }
  }

  /// Get maintenance statistics
  /// Returns summary of maintenance issues across all properties
  Future<MaintenanceStatistics> getMaintenanceStatistics() async {
    try {
      print('StatisticsService: Fetching maintenance statistics...');

      final response = await get(
        '/Statistics/maintenance',
        authenticated: true,
      );

      final MaintenanceStatistics maintenanceStats =
          MaintenanceStatistics.fromJson(jsonDecode(response.body));

      print('StatisticsService: Successfully fetched maintenance statistics.');

      return maintenanceStats;
    } catch (e) {
      print('StatisticsService: Error fetching maintenance statistics: $e');
      rethrow;
    }
  }

  /// Get financial statistics
  /// Returns detailed financial data including revenue trends and breakdowns
  Future<FinancialStatisticsApi> getFinancialStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      print('StatisticsService: Fetching financial statistics...');

      // Prepare request body for POST /financial endpoint
      final requestBody = {
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'period': null, // Optional field in backend request
      };

      final response = await post(
        '/Statistics/financial',
        requestBody,
        authenticated: true,
      );

      // Parse the FinancialSummaryDto from backend
      final summaryDto = FinancialSummaryDto.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );

      // Convert to FinancialStatisticsApi for UI compatibility
      final financialStats = FinancialStatisticsApi.fromSummaryDto(summaryDto);

      print('StatisticsService: Successfully fetched financial statistics.');

      return financialStats;
    } catch (e) {
      print('StatisticsService: Error fetching financial statistics: $e');
      rethrow;
    }
  }
}
