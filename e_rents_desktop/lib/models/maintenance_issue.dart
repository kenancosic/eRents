import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/image_info.dart' as erents;

enum IssuePriority { low, medium, high, emergency }

enum IssueStatus { pending, inProgress, completed, cancelled }

class MaintenanceIssue {
  final String id;
  final String propertyId;
  final String title;
  final String description;
  final IssuePriority priority;
  final IssueStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final double? cost;
  final String? assignedTo;
  final List<erents.ImageInfo> images;
  final String reportedBy;
  final String? resolutionNotes;
  final String? category; // e.g., plumbing, electrical, structural, etc.
  final bool requiresInspection;
  final bool isTenantComplaint;

  MaintenanceIssue({
    required this.id,
    required this.propertyId,
    required this.title,
    required this.description,
    required this.priority,
    this.status = IssueStatus.pending,
    required this.createdAt,
    this.resolvedAt,
    this.cost,
    this.assignedTo,
    this.images = const [],
    required this.reportedBy,
    this.resolutionNotes,
    this.category,
    this.requiresInspection = false,
    this.isTenantComplaint = false,
  });

  factory MaintenanceIssue.fromJson(Map<String, dynamic> json) {
    return MaintenanceIssue(
      id: json['id'] as String,
      propertyId: json['propertyId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      priority: IssuePriority.values.firstWhere(
        (e) => e.toString() == 'IssuePriority.${json['priority']}',
      ),
      status: IssueStatus.values.firstWhere(
        (e) => e.toString() == 'IssueStatus.${json['status']}',
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      resolvedAt:
          json['resolvedAt'] != null
              ? DateTime.parse(json['resolvedAt'] as String)
              : null,
      cost: json['cost'] as double?,
      assignedTo: json['assignedTo'] as String?,
      images:
          (json['images'] as List? ?? [])
              .map(
                (e) =>
                    e is String
                        ? erents.ImageInfo(id: e, url: e)
                        : erents.ImageInfo.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      reportedBy: json['reportedBy'] as String,
      resolutionNotes: json['resolutionNotes'] as String?,
      category: json['category'] as String?,
      requiresInspection: json['requiresInspection'] as bool? ?? false,
      isTenantComplaint: json['isTenantComplaint'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'title': title,
      'description': description,
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'cost': cost,
      'assignedTo': assignedTo,
      'images': images.map((e) => e.toJson()).toList(),
      'reportedBy': reportedBy,
      'resolutionNotes': resolutionNotes,
      'category': category,
      'requiresInspection': requiresInspection,
      'isTenantComplaint': isTenantComplaint,
    };
  }

  MaintenanceIssue copyWith({
    String? id,
    String? propertyId,
    String? title,
    String? description,
    IssuePriority? priority,
    IssueStatus? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    double? cost,
    String? assignedTo,
    List<erents.ImageInfo>? images,
    String? reportedBy,
    String? resolutionNotes,
    String? category,
    bool? requiresInspection,
    bool? isTenantComplaint,
  }) {
    return MaintenanceIssue(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      cost: cost ?? this.cost,
      assignedTo: assignedTo ?? this.assignedTo,
      images: images ?? this.images,
      reportedBy: reportedBy ?? this.reportedBy,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      category: category ?? this.category,
      requiresInspection: requiresInspection ?? this.requiresInspection,
      isTenantComplaint: isTenantComplaint ?? this.isTenantComplaint,
    );
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

  Color get statusColor {
    switch (status) {
      case IssueStatus.pending:
        return Colors.orange;
      case IssueStatus.inProgress:
        return Colors.blue;
      case IssueStatus.completed:
        return Colors.green;
      case IssueStatus.cancelled:
        return Colors.grey;
    }
  }
}
