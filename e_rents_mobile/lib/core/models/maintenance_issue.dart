import 'package:e_rents_mobile/core/models/image_model.dart';

enum MaintenanceIssueStatus {
  reported,
  inProgress,
  resolved,
  closed,
}

enum MaintenanceIssuePriority {
  low,
  medium,
  high,
  urgent,
}

class MaintenanceIssue {
  final int? issueId;
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
    this.issueId,
    required this.propertyId,
    required this.tenantId,
    required this.title,
    required this.description,
    required this.priority,
    this.status = MaintenanceIssueStatus.reported,
    required this.dateReported,
    this.dateResolved,
    this.images,
    this.landlordResponse,
    this.landlordResponseDate,
  });

  factory MaintenanceIssue.fromJson(Map<String, dynamic> json) {
    return MaintenanceIssue(
      issueId: json['issueId'],
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
        orElse: () => MaintenanceIssueStatus.reported,
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
      'issueId': issueId,
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
    int? issueId,
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
      issueId: issueId ?? this.issueId,
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
