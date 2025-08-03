import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';

part 'maintenance_issue.g.dart';

enum IssuePriority { low, medium, high, emergency }

class IssuePriorityConverter implements JsonConverter<IssuePriority, String> {
  const IssuePriorityConverter();

  @override
  IssuePriority fromJson(String json) =>
      IssuePriority.values.firstWhere((e) => e.name == json);

  @override
  String toJson(IssuePriority object) => object.name;
}

enum IssueStatus { pending, inProgress, completed, cancelled }

class IssueStatusConverter implements JsonConverter<IssueStatus, String> {
  const IssueStatusConverter();

  @override
  IssueStatus fromJson(String json) =>
      IssueStatus.values.firstWhere((e) => e.name == json);

  @override
  String toJson(IssueStatus object) => object.name;
}

@JsonSerializable()
class MaintenanceIssue {
  final int maintenanceIssueId;
  final int propertyId;
  final String title;
  final String? description;
  @IssuePriorityConverter()
  final IssuePriority priority;
  @IssueStatusConverter()
  final IssueStatus status;
  final DateTime? resolvedAt;
  final double? cost;
  final int? assignedToUserId;
  final int reportedByUserId;
  final String? resolutionNotes;
  final String? category;
  final bool requiresInspection;
  final bool isTenantComplaint;
  final List<int> imageIds;
  final DateTime createdAt;
  final int? tenantId;

  MaintenanceIssue({
    required this.maintenanceIssueId,
    required this.propertyId,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    this.resolvedAt,
    this.cost,
    this.assignedToUserId,
    required this.reportedByUserId,
    this.resolutionNotes,
    this.category,
    required this.requiresInspection,
    required this.isTenantComplaint,
    required this.imageIds,
    required this.createdAt,
    this.tenantId,
  });

  factory MaintenanceIssue.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceIssueFromJson(json);

  Map<String, dynamic> toJson() => _$MaintenanceIssueToJson(this);

  MaintenanceIssue copyWith({
    int? maintenanceIssueId,
    int? propertyId,
    String? title,
    String? description,
    IssuePriority? priority,
    IssueStatus? status,
    DateTime? resolvedAt,
    double? cost,
    int? assignedToUserId,
    int? reportedByUserId,
    String? resolutionNotes,
    String? category,
    bool? requiresInspection,
    bool? isTenantComplaint,
    List<int>? imageIds,
    DateTime? createdAt,
    int? tenantId,
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
      category: category ?? this.category,
      requiresInspection: requiresInspection ?? this.requiresInspection,
      isTenantComplaint: isTenantComplaint ?? this.isTenantComplaint,
      imageIds: imageIds ?? this.imageIds,
      createdAt: createdAt ?? this.createdAt,
      tenantId: tenantId ?? this.tenantId,
    );
  }

  static MaintenanceIssue empty() {
    return MaintenanceIssue(
      maintenanceIssueId: 0,
      propertyId: 0,
      title: '',
      description: '',
      priority: IssuePriority.medium,
      status: IssueStatus.pending,
      reportedByUserId: 0,
      requiresInspection: false,
      isTenantComplaint: false,
      imageIds: [],
      createdAt: DateTime.now(),
    );
  }

  // Getters for UI
  String? get tenantName =>
      null; // Placeholder, would be fetched from tenant data

  Color get statusColor {
    switch (status) {
      case IssueStatus.pending:
        return Colors.orange;
      case IssueStatus.inProgress:
        return Colors.blue;
      case IssueStatus.completed:
        return Colors.green;
      case IssueStatus.cancelled:
        return Colors.red;
    }
  }

  Color get priorityColor {
    switch (priority) {
      case IssuePriority.low:
        return Colors.green;
      case IssuePriority.medium:
        return Colors.orange;
      case IssuePriority.high:
        return Colors.red;
      case IssuePriority.emergency:
        return Colors.purple;
    }
  }
}
