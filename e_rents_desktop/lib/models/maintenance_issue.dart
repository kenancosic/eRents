import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/image_info.dart' as erents;

enum IssuePriority { low, medium, high, emergency }

enum IssueStatus { pending, inProgress, completed, cancelled }

class MaintenanceIssue {
  final int maintenanceIssueId;
  final int propertyId;
  final int tenantId;
  final String title;
  final String description;
  final IssuePriority priority;
  final IssueStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final List<int> imageIds;
  final String? landlordResponse;
  final DateTime? landlordResponseDate;
  final String? category;
  final bool requiresInspection;
  final bool isTenantComplaint;
  final double? cost;
  final String? resolutionNotes;
  final String? propertyName;
  final String? propertyAddress;
  final String? userFirstNameTenant;
  final String? userLastNameTenant;
  final String? userEmailTenant;
  final String? userFirstNameLandlord;
  final String? userLastNameLandlord;

  MaintenanceIssue({
    required this.maintenanceIssueId,
    required this.propertyId,
    required this.tenantId,
    required this.title,
    required this.description,
    required this.priority,
    this.status = IssueStatus.pending,
    required this.createdAt,
    this.resolvedAt,
    this.imageIds = const [],
    this.landlordResponse,
    this.landlordResponseDate,
    this.category,
    this.requiresInspection = false,
    this.isTenantComplaint = false,
    this.cost,
    this.resolutionNotes,
    this.propertyName,
    this.propertyAddress,
    this.userFirstNameTenant,
    this.userLastNameTenant,
    this.userEmailTenant,
    this.userFirstNameLandlord,
    this.userLastNameLandlord,
  });

  factory MaintenanceIssue.fromJson(Map<String, dynamic> json) {
    return MaintenanceIssue(
      maintenanceIssueId:
          json['maintenanceIssueId'] as int? ??
          json['IssueId'] as int? ??
          json['issueId'] as int? ??
          json['id'] as int? ??
          0,
      propertyId: json['propertyId'] as int? ?? 0,
      tenantId: json['tenantId'] as int? ?? json['reportedBy'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priority: _parsePriority(json['priority']),
      status: _parseStatus(json['status']),
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : json['dateReported'] != null
              ? DateTime.parse(json['dateReported'] as String)
              : DateTime.now(),
      resolvedAt:
          json['resolvedAt'] != null
              ? DateTime.parse(json['resolvedAt'] as String)
              : json['dateResolved'] != null
              ? DateTime.parse(json['dateResolved'] as String)
              : null,
      imageIds: _parseImageIds(json['imageIds']),
      landlordResponse: json['landlordResponse'] as String?,
      landlordResponseDate:
          json['landlordResponseDate'] != null
              ? DateTime.parse(json['landlordResponseDate'] as String)
              : null,
      category: json['category'] as String?,
      requiresInspection: json['requiresInspection'] as bool? ?? false,
      isTenantComplaint: json['isTenantComplaint'] as bool? ?? false,
      cost: (json['cost'] as num?)?.toDouble(),
      resolutionNotes: json['resolutionNotes'] as String?,
      propertyName: json['propertyName'] as String?,
      propertyAddress: json['propertyAddress'] as String?,
      userFirstNameTenant: json['userFirstNameTenant'] as String?,
      userLastNameTenant: json['userLastNameTenant'] as String?,
      userEmailTenant: json['userEmailTenant'] as String?,
      userFirstNameLandlord: json['userFirstNameLandlord'] as String?,
      userLastNameLandlord: json['userLastNameLandlord'] as String?,
    );
  }

  factory MaintenanceIssue.empty() {
    return MaintenanceIssue(
      maintenanceIssueId: 0,
      propertyId: 0,
      tenantId: 0,
      title: '',
      description: '',
      priority: IssuePriority.medium,
      createdAt: DateTime.now(),
      category: '',
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

  static List<int> _parseImageIds(dynamic imageIdsValue) {
    if (imageIdsValue == null) return [];

    try {
      if (imageIdsValue is List) {
        return imageIdsValue
            .map((e) {
              if (e is int) return e;
              if (e is String) return int.tryParse(e) ?? 0;
              if (e is Map<String, dynamic> && e['id'] != null) {
                return e['id'] as int;
              }
              return 0;
            })
            .where((id) => id > 0)
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'maintenanceIssueId': maintenanceIssueId,
      'propertyId': propertyId,
      'tenantId': tenantId,
      'title': title,
      'description': description,
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'dateReported': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'dateResolved': resolvedAt?.toIso8601String(),
      'imageIds': imageIds,
      'landlordResponse': landlordResponse,
      'landlordResponseDate': landlordResponseDate?.toIso8601String(),
      'category': category,
      'requiresInspection': requiresInspection,
      'isTenantComplaint': isTenantComplaint,
      'cost': cost,
      'resolutionNotes': resolutionNotes,
    };
  }

  MaintenanceIssue copyWith({
    int? maintenanceIssueId,
    int? propertyId,
    int? tenantId,
    String? title,
    String? description,
    IssuePriority? priority,
    IssueStatus? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    List<int>? imageIds,
    String? landlordResponse,
    DateTime? landlordResponseDate,
    String? category,
    bool? requiresInspection,
    bool? isTenantComplaint,
    double? cost,
    String? resolutionNotes,
    String? propertyName,
    String? propertyAddress,
    String? userFirstNameTenant,
    String? userLastNameTenant,
    String? userEmailTenant,
    String? userFirstNameLandlord,
    String? userLastNameLandlord,
  }) {
    return MaintenanceIssue(
      maintenanceIssueId: maintenanceIssueId ?? this.maintenanceIssueId,
      propertyId: propertyId ?? this.propertyId,
      tenantId: tenantId ?? this.tenantId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      imageIds: imageIds ?? this.imageIds,
      landlordResponse: landlordResponse ?? this.landlordResponse,
      landlordResponseDate: landlordResponseDate ?? this.landlordResponseDate,
      category: category ?? this.category,
      requiresInspection: requiresInspection ?? this.requiresInspection,
      isTenantComplaint: isTenantComplaint ?? this.isTenantComplaint,
      cost: cost ?? this.cost,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      propertyName: propertyName ?? this.propertyName,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      userFirstNameTenant: userFirstNameTenant ?? this.userFirstNameTenant,
      userLastNameTenant: userLastNameTenant ?? this.userLastNameTenant,
      userEmailTenant: userEmailTenant ?? this.userEmailTenant,
      userFirstNameLandlord:
          userFirstNameLandlord ?? this.userFirstNameLandlord,
      userLastNameLandlord: userLastNameLandlord ?? this.userLastNameLandlord,
    );
  }

  String? get tenantName =>
      !((userFirstNameTenant?.isEmpty ?? true) &&
              (userLastNameTenant?.isEmpty ?? true))
          ? '${userFirstNameTenant ?? ''} ${userLastNameTenant ?? ''}'.trim()
          : null;

  String? get landlordName =>
      !((userFirstNameLandlord?.isEmpty ?? true) &&
              (userLastNameLandlord?.isEmpty ?? true))
          ? '${userFirstNameLandlord ?? ''} ${userLastNameLandlord ?? ''}'
              .trim()
          : null;

  int get reportedBy => tenantId;
  List<erents.ImageInfo> get images =>
      imageIds
          .map((id) => erents.ImageInfo(id: id, url: '/Image/$id'))
          .toList();

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

extension IssueStatusExtension on IssueStatus {
  String get displayName {
    switch (this) {
      case IssueStatus.pending:
        return 'Pending';
      case IssueStatus.inProgress:
        return 'In Progress';
      case IssueStatus.completed:
        return 'Completed';
      case IssueStatus.cancelled:
        return 'Cancelled';
      default:
        final name = toString().split('.').last;
        return name[0].toUpperCase() + name.substring(1);
    }
  }

  Color get statusColor {
    switch (this) {
      case IssueStatus.pending:
        return Colors.orange;
      case IssueStatus.inProgress:
        return Colors.blue;
      case IssueStatus.completed:
        return Colors.green;
      case IssueStatus.cancelled:
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}

extension IssuePriorityExtension on IssuePriority {
  String get displayName {
    switch (this) {
      case IssuePriority.low:
        return 'Low';
      case IssuePriority.medium:
        return 'Medium';
      case IssuePriority.high:
        return 'High';
      case IssuePriority.emergency:
        return 'Emergency';
      default:
        final name = toString().split('.').last;
        return name[0].toUpperCase() + name.substring(1);
    }
  }

  Color get priorityColor {
    switch (this) {
      case IssuePriority.low:
        return Colors.green;
      case IssuePriority.medium:
        return Colors.amber;
      case IssuePriority.high:
        return Colors.orange;
      case IssuePriority.emergency:
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}
