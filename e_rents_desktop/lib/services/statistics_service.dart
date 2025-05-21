import 'dart:convert';
import 'package:e_rents_desktop/services/api_service.dart';

class DashboardStatistics {
  final int totalProperties;
  final int occupiedProperties;
  final double occupancyRate;
  final double averageRating;
  final List<PopularProperty> topProperties;
  final int pendingMaintenanceIssues;
  final double monthlyRevenue;
  final double yearlyRevenue;

  DashboardStatistics({
    required this.totalProperties,
    required this.occupiedProperties,
    required this.occupancyRate,
    required this.averageRating,
    required this.topProperties,
    required this.pendingMaintenanceIssues,
    required this.monthlyRevenue,
    required this.yearlyRevenue,
  });

  factory DashboardStatistics.fromJson(Map<String, dynamic> json) {
    return DashboardStatistics(
      totalProperties: json['totalProperties'] ?? 0,
      occupiedProperties: json['occupiedProperties'] ?? 0,
      occupancyRate: json['occupancyRate']?.toDouble() ?? 0.0,
      averageRating: json['averageRating']?.toDouble() ?? 0.0,
      topProperties:
          (json['topProperties'] as List<dynamic>?)
              ?.map((property) => PopularProperty.fromJson(property))
              .toList() ??
          [],
      pendingMaintenanceIssues: json['pendingMaintenanceIssues'] ?? 0,
      monthlyRevenue: json['monthlyRevenue']?.toDouble() ?? 0.0,
      yearlyRevenue: json['yearlyRevenue']?.toDouble() ?? 0.0,
    );
  }
}

class PopularProperty {
  final int propertyId;
  final String name;
  final int bookingCount;
  final double totalRevenue;
  final double? averageRating;

  PopularProperty({
    required this.propertyId,
    required this.name,
    required this.bookingCount,
    required this.totalRevenue,
    this.averageRating,
  });

  factory PopularProperty.fromJson(Map<String, dynamic> json) {
    return PopularProperty(
      propertyId: json['propertyId'] ?? 0,
      name: json['name'] ?? '',
      bookingCount: json['bookingCount'] ?? 0,
      totalRevenue: json['totalRevenue']?.toDouble() ?? 0.0,
      averageRating: json['averageRating']?.toDouble(),
    );
  }
}

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

class StatisticsService {
  final ApiService _apiService;

  StatisticsService(this._apiService);

  Future<DashboardStatistics> getDashboardStatistics() async {
    try {
      final response = await _apiService.get('/Statistics/dashboard');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DashboardStatistics.fromJson(data);
      } else {
        throw Exception(
          'Failed to load dashboard statistics: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching dashboard statistics: $e');
    }
  }

  Future<FinancialStatistics> getFinancialStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
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
      final response = await _apiService.get(endpoint);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FinancialStatistics.fromJson(data);
      } else {
        throw Exception(
          'Failed to load financial statistics: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching financial statistics: $e');
    }
  }
}
