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
  final int tenantId;
  final String title;
  final String description;
  final MaintenanceIssuePriority priority;
  final MaintenanceIssueStatus status;
  final DateTime dateReported;
  final DateTime? dateResolved;
  final List<ImageModel>? images;
  final String? landlordResponse;
  final DateTime? landlordResponseDate;

  MaintenanceIssue({
    this.maintenanceIssueId,
    required this.propertyId,
    required this.tenantId,
    required this.title,
    required this.description,
    required this.priority,
    this.status = MaintenanceIssueStatus.pending,
    required this.dateReported,
    this.dateResolved,
    this.images,
    this.landlordResponse,
    this.landlordResponseDate,
  });

  factory MaintenanceIssue.fromJson(Map<String, dynamic> json) {
    return MaintenanceIssue(
      maintenanceIssueId: json['maintenanceIssueId'] ?? json['issueId'],
      propertyId: json['propertyId'],
      tenantId: json['tenantId'],
      title: json['title'],
      description: json['description'],
      priority: MaintenanceIssuePriority.values.firstWhere(
        (e) => e.toString().split('.').last == json['priority'],
        orElse: () => MaintenanceIssuePriority.medium,
      ),
      status: MaintenanceIssueStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => MaintenanceIssueStatus.pending,
      ),
      dateReported: DateTime.parse(json['dateReported']),
      dateResolved: json['dateResolved'] != null
          ? DateTime.parse(json['dateResolved'])
          : null,
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
      'tenantId': tenantId,
      'title': title,
      'description': description,
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'dateReported': dateReported.toIso8601String(),
      'dateResolved': dateResolved?.toIso8601String(),
      'images': images?.map((img) => img.toJson()).toList(),
      'landlordResponse': landlordResponse,
      'landlordResponseDate': landlordResponseDate?.toIso8601String(),
    };
  }

  MaintenanceIssue copyWith({
    int? maintenanceIssueId,
    int? propertyId,
    int? tenantId,
    String? title,
    String? description,
    MaintenanceIssuePriority? priority,
    MaintenanceIssueStatus? status,
    DateTime? dateReported,
    DateTime? dateResolved,
    List<ImageModel>? images,
    String? landlordResponse,
    DateTime? landlordResponseDate,
  }) {
    return MaintenanceIssue(
      maintenanceIssueId: maintenanceIssueId ?? this.maintenanceIssueId,
      propertyId: propertyId ?? this.propertyId,
      tenantId: tenantId ?? this.tenantId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dateReported: dateReported ?? this.dateReported,
      dateResolved: dateResolved ?? this.dateResolved,
      images: images ?? this.images,
      landlordResponse: landlordResponse ?? this.landlordResponse,
      landlordResponseDate: landlordResponseDate ?? this.landlordResponseDate,
    );
  }
}
