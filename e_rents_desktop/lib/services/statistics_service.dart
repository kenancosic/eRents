import 'dart:convert';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/models/statistics/property_statistics.dart';
import 'package:e_rents_desktop/models/statistics/maintenance_statistics.dart';
import 'package:e_rents_desktop/models/statistics/dashboard_statistics.dart';

class FinancialStatistics {
  final double currentMonthRevenue;
  final double previousMonthRevenue;
  final double projectedRevenue;
  final List<MonthlyRevenue> revenueHistory;
  final Map<String, double> revenueByPropertyType;

  FinancialStatistics({
    required this.currentMonthRevenue,
    required this.previousMonthRevenue,
    required this.projectedRevenue,
    required this.revenueHistory,
    required this.revenueByPropertyType,
  });

  factory FinancialStatistics.fromJson(Map<String, dynamic> json) {
    // Convert revenueByPropertyType from JSON
    Map<String, double> revenueByType = {};
    if (json['revenueByPropertyType'] != null) {
      json['revenueByPropertyType'].forEach((key, value) {
        revenueByType[key] = value.toDouble();
      });
    }

    return FinancialStatistics(
      currentMonthRevenue: json['currentMonthRevenue']?.toDouble() ?? 0.0,
      previousMonthRevenue: json['previousMonthRevenue']?.toDouble() ?? 0.0,
      projectedRevenue: json['projectedRevenue']?.toDouble() ?? 0.0,
      revenueHistory:
          (json['revenueHistory'] as List<dynamic>?)
              ?.map((item) => MonthlyRevenue.fromJson(item))
              .toList() ??
          [],
      revenueByPropertyType: revenueByType,
    );
  }
}

class MonthlyRevenue {
  final int year;
  final int month;
  final double revenue;

  MonthlyRevenue({
    required this.year,
    required this.month,
    required this.revenue,
  });

  factory MonthlyRevenue.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenue(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      revenue: json['revenue']?.toDouble() ?? 0.0,
    );
  }
}

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
  Future<Map<String, dynamic>> getFinancialStatistics([
    Map<String, String>? filters,
  ]) async {
    try {
      print('StatisticsService: Fetching financial statistics...');

      String endpoint = '/Statistics/financial';
      if (filters != null && filters.isNotEmpty) {
        final queryString = Uri(queryParameters: filters).query;
        endpoint += '?$queryString';
      }

      final response = await get(endpoint, authenticated: true);

      final financialData = jsonDecode(response.body) as Map<String, dynamic>;

      print('StatisticsService: Successfully fetched financial statistics.');

      return financialData;
    } catch (e) {
      print('StatisticsService: Error fetching financial statistics: $e');
      rethrow;
    }
  }
}
