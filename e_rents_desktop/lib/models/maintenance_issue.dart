import 'package:e_rents_desktop/models/enums/maintenance_issue_status.dart';
import 'package:e_rents_desktop/models/enums/maintenance_issue_priority.dart';


class MaintenanceIssue {
  final int maintenanceIssueId;
  final int propertyId;
  final String title;
  final String? description;
  final MaintenanceIssuePriority priority;
  final MaintenanceIssueStatus status;
  final DateTime? resolvedAt;
  final double? cost;
  final int? assignedToUserId;
  final int reportedByUserId;
  final String? resolutionNotes;
  final bool isTenantComplaint;
  final List<int> imageIds;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? createdBy;
  final int? modifiedBy;

  const MaintenanceIssue({
    required this.maintenanceIssueId,
    required this.propertyId,
    required this.title,
    this.description,
    this.priority = MaintenanceIssuePriority.medium,
    this.status = MaintenanceIssueStatus.pending,
    this.resolvedAt,
    this.cost,
    this.assignedToUserId,
    required this.reportedByUserId,
    this.resolutionNotes,
    this.isTenantComplaint = false,
    this.imageIds = const [],
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.modifiedBy,
  });

  factory MaintenanceIssue.fromJson(Map<String, dynamic> json) {
    return MaintenanceIssue(
      maintenanceIssueId: (json['maintenanceIssueId'] as num).toInt(),
      propertyId: (json['propertyId'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: MaintenanceIssuePriorityX.parse(json['priority']),
      status: MaintenanceIssueStatusX.parse(json['status']),
      resolvedAt: json['resolvedAt'] == null
          ? null
          : DateTime.parse(json['resolvedAt'] as String),
      cost: (json['cost'] as num?)?.toDouble(),
      assignedToUserId: (json['assignedToUserId'] as num?)?.toInt(),
      reportedByUserId: (json['reportedByUserId'] as num).toInt(),
      resolutionNotes: json['resolutionNotes'] as String?,
      isTenantComplaint: json['isTenantComplaint'] as bool? ?? false,
      imageIds: (json['imageIds'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      createdBy: (json['createdBy'] as num?)?.toInt(),
      modifiedBy: (json['modifiedBy'] as num?)?.toInt(),
    ).copyWith(
      // Ensure updatedAt has a sensible default
      updatedAt: (json['updatedAt'] == null)
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'maintenanceIssueId': maintenanceIssueId,
        'propertyId': propertyId,
        'title': title,
        'description': description,
        'priority': priority.name,
        'status': status.name,
        'resolvedAt': resolvedAt?.toIso8601String(),
        'cost': cost,
        'assignedToUserId': assignedToUserId,
        'reportedByUserId': reportedByUserId,
        'resolutionNotes': resolutionNotes,
        'isTenantComplaint': isTenantComplaint,
        'imageIds': imageIds,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': (updatedAt ?? createdAt).toIso8601String(),
        'createdBy': createdBy,
        'modifiedBy': modifiedBy,
      };

  // Factory constructor for empty instance
  factory MaintenanceIssue.empty() => MaintenanceIssue(
        maintenanceIssueId: 0,
        propertyId: 0,
        title: '',
        reportedByUserId: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  // CopyWith method for immutable updates
  MaintenanceIssue copyWith({
    int? maintenanceIssueId,
    int? propertyId,
    String? title,
    String? description,
    MaintenanceIssuePriority? priority,
    MaintenanceIssueStatus? status,
    DateTime? resolvedAt,
    double? cost,
    int? assignedToUserId,
    int? reportedByUserId,
    String? resolutionNotes,
    bool? isTenantComplaint,
    List<int>? imageIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? createdBy,
    int? modifiedBy,
    int? tenantId, // For convenience in forms
  }) {
    return MaintenanceIssue(
      maintenanceIssueId: maintenanceIssueId ?? this.maintenanceIssueId,
      propertyId: propertyId ?? this.propertyId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      cost: cost ?? this.cost,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      reportedByUserId: reportedByUserId ?? this.reportedByUserId,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      isTenantComplaint: isTenantComplaint ?? this.isTenantComplaint,
      imageIds: imageIds ?? this.imageIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      modifiedBy: modifiedBy ?? this.modifiedBy,
    );
  }

  // Convenience getters for maintenance management
  // Note: Color/icon UI helpers have been moved to
  // lib/presentation/extensions/enum_ui_extensions.dart

  // Tenant-related getters for UI convenience
  int get tenantId => reportedByUserId;
  
  String get tenantName => 'Tenant'; // Placeholder - would need user lookup in real implementation
}