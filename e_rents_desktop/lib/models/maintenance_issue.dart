import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/image_info.dart' as erents;

enum IssuePriority { low, medium, high, emergency }

enum IssueStatus { pending, inProgress, completed, cancelled }

class MaintenanceIssue {
  final int id;
  final int propertyId;
  final String title;
  final String description;
  final IssuePriority priority;
  final IssueStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final double? cost;
  final String? assignedTo;
  final List<erents.ImageInfo> images;
  final int reportedBy;
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
      id: json['maintenanceIssueId'] as int? ?? json['id'] as int? ?? 0,
      propertyId: json['propertyId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priority: _parsePriority(json['priority']),
      status: _parseStatus(json['status']),
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      resolvedAt:
          json['resolvedAt'] != null
              ? DateTime.parse(json['resolvedAt'] as String)
              : null,
      cost: (json['cost'] as num?)?.toDouble(),
      assignedTo: json['assignedTo'] as String?,
      images: _parseImages(json['images']),
      reportedBy:
          json['reportedBy'] as int? ?? json['reportedByUserId'] as int? ?? 0,
      resolutionNotes: json['resolutionNotes'] as String?,
      category: json['category'] as String?,
      requiresInspection: json['requiresInspection'] as bool? ?? false,
      isTenantComplaint: json['isTenantComplaint'] as bool? ?? false,
    );
  }

  static IssuePriority _parsePriority(dynamic priority) {
    if (priority == null) return IssuePriority.medium;

    String priorityStr = priority.toString().toLowerCase();
    switch (priorityStr) {
      case 'low':
        return IssuePriority.low;
      case 'high':
        return IssuePriority.high;
      case 'emergency':
        return IssuePriority.emergency;
      default:
        return IssuePriority.medium;
    }
  }

  static IssueStatus _parseStatus(dynamic status) {
    if (status == null) return IssueStatus.pending;

    String statusStr = status.toString().toLowerCase();
    switch (statusStr) {
      case 'inprogress':
      case 'in_progress':
        return IssueStatus.inProgress;
      case 'completed':
        return IssueStatus.completed;
      case 'cancelled':
        return IssueStatus.cancelled;
      default:
        return IssueStatus.pending;
    }
  }

  static List<erents.ImageInfo> _parseImages(dynamic imagesValue) {
    if (imagesValue == null) return [];

    try {
      final List<dynamic> imagesList = imagesValue as List;
      return imagesList.map((e) {
        if (e is String) {
          return erents.ImageInfo(id: int.parse(e), url: e);
        } else if (e is Map<String, dynamic>) {
          return erents.ImageInfo.fromJson(e);
        } else {
          return erents.ImageInfo(id: 0, url: '');
        }
      }).toList();
    } catch (e) {
      return [];
    }
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
    int? id,
    int? propertyId,
    String? title,
    String? description,
    IssuePriority? priority,
    IssueStatus? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    double? cost,
    String? assignedTo,
    List<erents.ImageInfo>? images,
    int? reportedBy,
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
