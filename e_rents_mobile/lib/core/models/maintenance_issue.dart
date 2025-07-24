/// Maintenance Issue model aligned with backend entity structure for universal filtering
///
/// Backend MaintenanceIssue Entity fields:
/// - MaintenanceIssueId, PropertyId, Title, Description, PriorityId, StatusId
/// - CreatedAt, ResolvedAt, AssignedToUserId, ReportedByUserId, Cost, ResolutionNotes
/// - Category, RequiresInspection, IsTenantComplaint
library;

import 'package:e_rents_mobile/core/models/image_model.dart';

enum MaintenanceIssueStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

enum MaintenanceIssuePriority {
  low,
  medium,
  high,
  emergency,
}

class MaintenanceIssue {
  final int? maintenanceIssueId;
  final int propertyId;
  final String title;
  final String description;

  // Backend aligned fields
  final int? priorityId; // ✅ NEW: ID for backend compatibility
  final int? statusId; // ✅ NEW: ID for backend compatibility
  final DateTime createdAt; // ✅ NEW: Renamed from dateReported
  final DateTime? resolvedAt; // ✅ RENAMED: from dateResolved
  final int? assignedToUserId; // ✅ NEW: Who is assigned to fix
  final int reportedByUserId; // ✅ RENAMED: from tenantId, more generic
  final double? cost; // ✅ NEW: Cost of repair
  final String? resolutionNotes; // ✅ NEW: Resolution details
  final String? category; // ✅ NEW: Issue category
  final bool? requiresInspection; // ✅ NEW: Inspection required
  final bool? isTenantComplaint; // ✅ NEW: Type classification

  // UI/UX fields (keep for mobile app functionality)
  final MaintenanceIssuePriority priority; // Keep for UI
  final MaintenanceIssueStatus status; // Keep for UI
  final DateTime dateReported; // Keep for backward compatibility
  final DateTime? dateResolved; // Keep for backward compatibility
  final int tenantId; // Keep for backward compatibility
  final List<ImageModel>? images;
  final String? landlordResponse;
  final DateTime? landlordResponseDate;

  MaintenanceIssue({
    this.maintenanceIssueId,
    required this.propertyId,
    required this.title,
    required this.description,
    this.priorityId,
    this.statusId,
    required this.createdAt,
    this.resolvedAt,
    this.assignedToUserId,
    required this.reportedByUserId,
    this.cost,
    this.resolutionNotes,
    this.category,
    this.requiresInspection,
    this.isTenantComplaint,
    // UI/UX fields with defaults
    this.priority = MaintenanceIssuePriority.medium,
    this.status = MaintenanceIssueStatus.pending,
    DateTime? dateReported,
    this.dateResolved,
    int? tenantId,
    this.images,
    this.landlordResponse,
    this.landlordResponseDate,
  })  : dateReported = dateReported ?? createdAt,
        tenantId = tenantId ?? reportedByUserId;

  factory MaintenanceIssue.fromJson(Map<String, dynamic> json) {
    return MaintenanceIssue(
      maintenanceIssueId: json['maintenanceIssueId'] ?? json['issueId'],
      propertyId: json['propertyId'],
      title: json['title'],
      description: json['description'],

      // Backend aligned fields
      priorityId: json['priorityId'],
      statusId: json['statusId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.parse(json['dateReported']), // Fallback
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'])
          : (json['dateResolved'] != null
              ? DateTime.parse(json['dateResolved'])
              : null),
      assignedToUserId: json['assignedToUserId'],
      reportedByUserId:
          json['reportedByUserId'] ?? json['tenantId'], // Fallback
      cost: json['cost']?.toDouble(),
      resolutionNotes: json['resolutionNotes'],
      category: json['category'],
      requiresInspection: json['requiresInspection'],
      isTenantComplaint: json['isTenantComplaint'],

      // UI/UX fields
      priority: _parsePriority(json['priority'], json['priorityId']),
      status: _parseStatus(json['status'], json['statusId']),
      dateReported: json['dateReported'] != null
          ? DateTime.parse(json['dateReported'])
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now()),
      dateResolved: json['dateResolved'] != null
          ? DateTime.parse(json['dateResolved'])
          : (json['resolvedAt'] != null
              ? DateTime.parse(json['resolvedAt'])
              : null),
      tenantId: json['tenantId'] ?? json['reportedByUserId'],
      images: json['images'] != null
          ? (json['images'] as List)
              .map((img) => ImageModel.fromJson(img))
              .toList()
          : null,
      landlordResponse: json['landlordResponse'],
      landlordResponseDate: json['landlordResponseDate'] != null
          ? DateTime.parse(json['landlordResponseDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maintenanceIssueId': maintenanceIssueId,
      'propertyId': propertyId,
      'title': title,
      'description': description,

      // Backend aligned fields
      'priorityId': priorityId ?? _getPriorityId(priority),
      'statusId': statusId ?? _getStatusId(status),
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'assignedToUserId': assignedToUserId,
      'reportedByUserId': reportedByUserId,
      'cost': cost,
      'resolutionNotes': resolutionNotes,
      'category': category,
      'requiresInspection': requiresInspection,
      'isTenantComplaint': isTenantComplaint,

      // UI/UX fields for backward compatibility
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'dateReported': dateReported.toIso8601String(),
      'dateResolved': dateResolved?.toIso8601String(),
      'tenantId': tenantId,
      'images': images?.map((img) => img.toJson()).toList(),
      'landlordResponse': landlordResponse,
      'landlordResponseDate': landlordResponseDate?.toIso8601String(),
    };
  }

  MaintenanceIssue copyWith({
    int? maintenanceIssueId,
    int? propertyId,
    String? title,
    String? description,
    int? priorityId,
    int? statusId,
    DateTime? createdAt,
    DateTime? resolvedAt,
    int? assignedToUserId,
    int? reportedByUserId,
    double? cost,
    String? resolutionNotes,
    String? category,
    bool? requiresInspection,
    bool? isTenantComplaint,
    MaintenanceIssuePriority? priority,
    MaintenanceIssueStatus? status,
    DateTime? dateReported,
    DateTime? dateResolved,
    int? tenantId,
    List<ImageModel>? images,
    String? landlordResponse,
    DateTime? landlordResponseDate,
  }) {
    return MaintenanceIssue(
      maintenanceIssueId: maintenanceIssueId ?? this.maintenanceIssueId,
      propertyId: propertyId ?? this.propertyId,
      title: title ?? this.title,
      description: description ?? this.description,
      priorityId: priorityId ?? this.priorityId,
      statusId: statusId ?? this.statusId,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      reportedByUserId: reportedByUserId ?? this.reportedByUserId,
      cost: cost ?? this.cost,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      category: category ?? this.category,
      requiresInspection: requiresInspection ?? this.requiresInspection,
      isTenantComplaint: isTenantComplaint ?? this.isTenantComplaint,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dateReported: dateReported ?? this.dateReported,
      dateResolved: dateResolved ?? this.dateResolved,
      tenantId: tenantId ?? this.tenantId,
      images: images ?? this.images,
      landlordResponse: landlordResponse ?? this.landlordResponse,
      landlordResponseDate: landlordResponseDate ?? this.landlordResponseDate,
    );
  }

  // Helper methods for enum/ID conversion
  static MaintenanceIssuePriority _parsePriority(
      dynamic priority, int? priorityId) {
    if (priority is String) {
      return MaintenanceIssuePriority.values.firstWhere(
        (e) => e.toString().split('.').last == priority,
        orElse: () => MaintenanceIssuePriority.medium,
      );
    }
    // Convert ID to enum (customize based on your backend mapping)
    switch (priorityId) {
      case 1:
        return MaintenanceIssuePriority.low;
      case 2:
        return MaintenanceIssuePriority.medium;
      case 3:
        return MaintenanceIssuePriority.high;
      case 4:
        return MaintenanceIssuePriority.emergency;
      default:
        return MaintenanceIssuePriority.medium;
    }
  }

  static MaintenanceIssueStatus _parseStatus(dynamic status, int? statusId) {
    if (status is String) {
      return MaintenanceIssueStatus.values.firstWhere(
        (e) => e.toString().split('.').last == status,
        orElse: () => MaintenanceIssueStatus.pending,
      );
    }
    // Convert ID to enum (customize based on your backend mapping)
    switch (statusId) {
      case 1:
        return MaintenanceIssueStatus.pending;
      case 2:
        return MaintenanceIssueStatus.inProgress;
      case 3:
        return MaintenanceIssueStatus.completed;
      case 4:
        return MaintenanceIssueStatus.cancelled;
      default:
        return MaintenanceIssueStatus.pending;
    }
  }

  static int _getPriorityId(MaintenanceIssuePriority priority) {
    switch (priority) {
      case MaintenanceIssuePriority.low:
        return 1;
      case MaintenanceIssuePriority.medium:
        return 2;
      case MaintenanceIssuePriority.high:
        return 3;
      case MaintenanceIssuePriority.emergency:
        return 4;
    }
  }

  static int _getStatusId(MaintenanceIssueStatus status) {
    switch (status) {
      case MaintenanceIssueStatus.pending:
        return 1;
      case MaintenanceIssueStatus.inProgress:
        return 2;
      case MaintenanceIssueStatus.completed:
        return 3;
      case MaintenanceIssueStatus.cancelled:
        return 4;
    }
  }

  // UI Helper properties
  String get priorityDisplay {
    switch (priority) {
      case MaintenanceIssuePriority.low:
        return 'Low Priority';
      case MaintenanceIssuePriority.medium:
        return 'Medium Priority';
      case MaintenanceIssuePriority.high:
        return 'High Priority';
      case MaintenanceIssuePriority.emergency:
        return 'Emergency';
    }
  }

  String get statusDisplay {
    switch (status) {
      case MaintenanceIssueStatus.pending:
        return 'Pending';
      case MaintenanceIssueStatus.inProgress:
        return 'In Progress';
      case MaintenanceIssueStatus.completed:
        return 'Completed';
      case MaintenanceIssueStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isResolved => status == MaintenanceIssueStatus.completed;
  bool get isUrgent => priority == MaintenanceIssuePriority.emergency;
  bool get hasImages => images != null && images!.isNotEmpty;
}
