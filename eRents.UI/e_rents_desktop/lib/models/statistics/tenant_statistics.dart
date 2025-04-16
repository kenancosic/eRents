class TenantStatistics {
  final int totalTenants;
  final int activeTenants;
  final int pendingTenants;
  final double averageTenancyDuration;
  final Map<String, int> tenantsByStatus;
  final Map<String, int> tenantsByProperty;
  final double averageSatisfactionScore;

  TenantStatistics({
    required this.totalTenants,
    required this.activeTenants,
    required this.pendingTenants,
    required this.averageTenancyDuration,
    required this.tenantsByStatus,
    required this.tenantsByProperty,
    required this.averageSatisfactionScore,
  });

  factory TenantStatistics.fromJson(Map<String, dynamic> json) {
    return TenantStatistics(
      totalTenants: json['totalTenants'] as int,
      activeTenants: json['activeTenants'] as int,
      pendingTenants: json['pendingTenants'] as int,
      averageTenancyDuration: json['averageTenancyDuration'] as double,
      tenantsByStatus: Map<String, int>.from(json['tenantsByStatus']),
      tenantsByProperty: Map<String, int>.from(json['tenantsByProperty']),
      averageSatisfactionScore: json['averageSatisfactionScore'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTenants': totalTenants,
      'activeTenants': activeTenants,
      'pendingTenants': pendingTenants,
      'averageTenancyDuration': averageTenancyDuration,
      'tenantsByStatus': tenantsByStatus,
      'tenantsByProperty': tenantsByProperty,
      'averageSatisfactionScore': averageSatisfactionScore,
    };
  }
}
