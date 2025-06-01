import 'dart:convert';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/models/statistics/property_statistics.dart';
import 'package:e_rents_desktop/models/statistics/maintenance_statistics.dart';
import 'package:e_rents_desktop/models/statistics/dashboard_statistics.dart';
import 'package:e_rents_desktop/models/statistics/financial_summary_dto.dart';
import 'package:e_rents_desktop/models/statistics/financial_statistics_api.dart';
import 'package:flutter/foundation.dart';

class StatisticsService extends ApiService {
  StatisticsService(super.baseUrl, super.secureStorageService);

  /// Get dashboard statistics for the authenticated landlord
  /// Returns overview of portfolio including occupancy, revenue, top properties, etc.
  Future<DashboardStatistics> getDashboardStatistics() async {
    try {
      debugPrint('StatisticsService: Fetching dashboard statistics...');

      final response = await get('/Statistics/dashboard', authenticated: true);

      final statistics = DashboardStatistics.fromJson(
        jsonDecode(response.body),
      );

      debugPrint(
        'StatisticsService: Successfully fetched dashboard statistics. Total Properties: ${statistics.totalProperties}',
      );

      return statistics;
    } catch (e) {
      debugPrint('StatisticsService: Error fetching dashboard statistics: $e');
      rethrow;
    }
  }

  /// Get property statistics
  /// Returns detailed statistics about property performance
  Future<PropertyStatistics> getPropertyStatistics() async {
    try {
      debugPrint('StatisticsService: Fetching property statistics...');

      final response = await get('/Statistics/properties', authenticated: true);

      final PropertyStatistics properties = PropertyStatistics.fromJson(
        jsonDecode(response.body),
      );

      debugPrint(
        'StatisticsService: Successfully fetched property statistics.',
      );

      return properties;
    } catch (e) {
      debugPrint('StatisticsService: Error fetching property statistics: $e');
      rethrow;
    }
  }

  /// Get maintenance statistics
  /// Returns summary of maintenance issues across all properties
  Future<MaintenanceStatistics> getMaintenanceStatistics() async {
    try {
      debugPrint('StatisticsService: Fetching maintenance statistics...');

      final response = await get(
        '/Statistics/maintenance',
        authenticated: true,
      );

      final MaintenanceStatistics maintenanceStats =
          MaintenanceStatistics.fromJson(jsonDecode(response.body));

      debugPrint(
        'StatisticsService: Successfully fetched maintenance statistics.',
      );

      return maintenanceStats;
    } catch (e) {
      debugPrint(
        'StatisticsService: Error fetching maintenance statistics: $e',
      );
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
      debugPrint(
        'StatisticsService: Fetching financial statistics for range: ${startDate?.toIso8601String()} to ${endDate?.toIso8601String()}',
      );

      // Prepare request body for POST /financial endpoint
      // Ensure dates are properly formatted for backend
      final requestBody = <String, dynamic>{
        'period': null, // Optional field in backend request
      };

      // Only add dates if they're provided
      if (startDate != null) {
        requestBody['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        requestBody['endDate'] = endDate.toIso8601String();
      }

      debugPrint('StatisticsService: Request body: $requestBody');

      final response = await post(
        '/Statistics/financial',
        requestBody,
        authenticated: true,
      );

      debugPrint('StatisticsService: Response status: ${response.statusCode}');
      debugPrint('StatisticsService: Response body: ${response.body}');

      // Parse the FinancialSummaryDto from backend
      final summaryDto = FinancialSummaryDto.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );

      debugPrint(
        'StatisticsService: Parsed FinancialSummaryDto with ${summaryDto.revenueHistory.length} monthly records',
      );

      // Convert to FinancialStatisticsApi for UI compatibility
      final financialStats = FinancialStatisticsApi.fromSummaryDto(summaryDto);

      debugPrint(
        'StatisticsService: Successfully fetched financial statistics.',
      );

      return financialStats;
    } catch (e) {
      debugPrint('StatisticsService: Error fetching financial statistics: $e');
      rethrow;
    }
  }

  /// Get financial statistics as raw DTO
  /// Returns detailed financial data including maintenance costs and monthly breakdown
  Future<FinancialSummaryDto> getFinancialSummaryDto({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint(
        'StatisticsService: Fetching financial summary DTO for range: ${startDate?.toIso8601String()} to ${endDate?.toIso8601String()}',
      );

      // Prepare request body for POST /financial endpoint
      final requestBody = <String, dynamic>{'period': null};

      // Only add dates if they're provided
      if (startDate != null) {
        requestBody['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        requestBody['endDate'] = endDate.toIso8601String();
      }

      debugPrint('StatisticsService: Request body: $requestBody');

      final response = await post(
        '/Statistics/financial',
        requestBody,
        authenticated: true,
      );

      debugPrint('StatisticsService: Response status: ${response.statusCode}');
      debugPrint('StatisticsService: Response body: ${response.body}');

      // Parse the FinancialSummaryDto from backend
      final summaryDto = FinancialSummaryDto.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );

      debugPrint(
        'StatisticsService: Successfully fetched financial summary DTO with ${summaryDto.revenueHistory.length} monthly records',
      );

      return summaryDto;
    } catch (e) {
      debugPrint('StatisticsService: Error fetching financial summary DTO: $e');
      rethrow;
    }
  }
}
