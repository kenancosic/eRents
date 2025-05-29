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
  StatisticsService(super.baseUrl, super.storageService);

  // Single comprehensive dashboard call
  Future<DashboardStatistics> getDashboardStatistics() async {
    final response = await get('/Statistics/dashboard', authenticated: true);
    final data = json.decode(response.body);
    return DashboardStatistics.fromJson(data);
  }

  // Legacy methods - kept for backward compatibility if needed
  Future<PropertyStatistics> getPropertyStatistics() async {
    final response = await get('/Statistics/properties', authenticated: true);
    final data = json.decode(response.body);
    return PropertyStatistics.fromJson(data);
  }

  Future<MaintenanceStatistics> getMaintenanceStatistics() async {
    final response = await get('/Statistics/maintenance', authenticated: true);
    final data = json.decode(response.body);
    return MaintenanceStatistics.fromJson(data);
  }

  Future<Map<String, dynamic>> getFinancialSummary() async {
    final response = await get('/Statistics/financial', authenticated: true);
    return json.decode(response.body);
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
