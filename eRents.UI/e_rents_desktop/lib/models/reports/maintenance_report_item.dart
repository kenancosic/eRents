enum MaintenancePriority { low, medium, high }

class MaintenanceReportItem {
  final String date;
  final String property;
  final String unit;
  final String issueType;
  final String status;
  final MaintenancePriority priority;
  final double cost;

  MaintenanceReportItem({
    required this.date,
    required this.property,
    required this.unit,
    required this.issueType,
    required this.status,
    required this.priority,
    required this.cost,
  });

  // For formatting in the UI
  String get formattedCost => '\$${cost.toStringAsFixed(2)}';
  String get priorityLabel {
    switch (priority) {
      case MaintenancePriority.low:
        return 'Low';
      case MaintenancePriority.medium:
        return 'Medium';
      case MaintenancePriority.high:
        return 'High';
    }
  }

  // For converting to/from JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'property': property,
      'unit': unit,
      'issueType': issueType,
      'status': status,
      'priority': priority.toString().split('.').last,
      'cost': cost,
    };
  }

  factory MaintenanceReportItem.fromJson(Map<String, dynamic> json) {
    return MaintenanceReportItem(
      date: json['date'],
      property: json['property'],
      unit: json['unit'],
      issueType: json['issueType'],
      status: json['status'],
      priority: _priorityFromString(json['priority']),
      cost: json['cost'],
    );
  }

  static MaintenancePriority _priorityFromString(String priorityStr) {
    switch (priorityStr.toLowerCase()) {
      case 'low':
        return MaintenancePriority.low;
      case 'medium':
        return MaintenancePriority.medium;
      case 'high':
        return MaintenancePriority.high;
      default:
        return MaintenancePriority.medium;
    }
  }
}
