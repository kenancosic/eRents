class MaintenanceStatistics {
  final int totalIssues;
  final int openIssues;
  final Map<String, int>
  issuesByCategory; // e.g., {'Plumbing': 3, 'Electrical': 2}
  final Map<String, int> monthlyIssues; // Last 6 months issues count

  MaintenanceStatistics({
    required this.totalIssues,
    required this.openIssues,
    required this.issuesByCategory,
    required this.monthlyIssues,
  });

  factory MaintenanceStatistics.fromJson(Map<String, dynamic> json) {
    return MaintenanceStatistics(
      totalIssues: json['totalIssues'] as int,
      openIssues: json['openIssues'] as int,
      issuesByCategory: Map<String, int>.from(json['issuesByCategory']),
      monthlyIssues: Map<String, int>.from(json['monthlyIssues']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalIssues': totalIssues,
      'openIssues': openIssues,
      'issuesByCategory': issuesByCategory,
      'monthlyIssues': monthlyIssues,
    };
  }
}
