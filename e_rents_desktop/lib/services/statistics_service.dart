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

  /// Get comprehensive dashboard statistics for landlords
  Future<DashboardStatistics> getDashboardStatistics() async {
    try {
      final response = await get(
        '/api/Statistics/dashboard',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DashboardStatistics.fromJson(jsonData);
      } else {
        throw Exception(
          'Failed to load dashboard statistics: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching dashboard statistics: $e');
    }
  }

  /// Get property statistics for landlords
  Future<Map<String, dynamic>> getPropertyStatistics() async {
    try {
      final response = await get(
        '/api/Statistics/properties',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load property statistics: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching property statistics: $e');
    }
  }

  /// Get maintenance statistics for landlords
  Future<Map<String, dynamic>> getMaintenanceStatistics() async {
    try {
      final response = await get(
        '/api/Statistics/maintenance',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load maintenance statistics: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching maintenance statistics: $e');
    }
  }

  /// Get financial summary for landlords
  Future<Map<String, dynamic>> getFinancialSummary({
    String? period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final requestBody = {
        'period': period,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      };

      final response = await post(
        '/api/Statistics/financial',
        requestBody,
        authenticated: true,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load financial summary: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching financial summary: $e');
    }
  }

  Future<FinancialStatistics> getFinancialStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Build query parameters
    String queryParams = '';
    if (startDate != null) {
      queryParams += 'startDate=${startDate.toIso8601String()}';
    }
    if (endDate != null) {
      queryParams += queryParams.isNotEmpty ? '&' : '';
      queryParams += 'endDate=${endDate.toIso8601String()}';
    }

    final endpoint =
        '/Statistics/financial${queryParams.isNotEmpty ? '?$queryParams' : ''}';
    final response = await get(endpoint, authenticated: true);
    final data = json.decode(response.body);
    return FinancialStatistics.fromJson(data);
  }
}
