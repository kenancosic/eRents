class MaintenanceStatistics {
  final int openIssuesCount;
  final int pendingIssuesCount;
  final int highPriorityIssuesCount;
  final int tenantComplaintsCount;

  MaintenanceStatistics({
    required this.openIssuesCount,
    required this.pendingIssuesCount,
    required this.highPriorityIssuesCount,
    required this.tenantComplaintsCount,
  });

  factory MaintenanceStatistics.fromJson(Map<String, dynamic> json) {
    return MaintenanceStatistics(
      openIssuesCount: json['openIssuesCount'] ?? 0,
      pendingIssuesCount: json['pendingIssuesCount'] ?? 0,
      highPriorityIssuesCount: json['highPriorityIssuesCount'] ?? 0,
      tenantComplaintsCount: json['tenantComplaintsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'openIssuesCount': openIssuesCount,
      'pendingIssuesCount': pendingIssuesCount,
      'highPriorityIssuesCount': highPriorityIssuesCount,
      'tenantComplaintsCount': tenantComplaintsCount,
    };
  }
}
