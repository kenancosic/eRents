// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_issue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaintenanceIssue _$MaintenanceIssueFromJson(Map<String, dynamic> json) =>
    MaintenanceIssue(
      maintenanceIssueId: (json['maintenanceIssueId'] as num).toInt(),
      propertyId: (json['propertyId'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: const IssuePriorityConverter().fromJson(
        json['priority'] as String,
      ),
      status: const IssueStatusConverter().fromJson(json['status'] as String),
      resolvedAt: json['resolvedAt'] == null
          ? null
          : DateTime.parse(json['resolvedAt'] as String),
      cost: (json['cost'] as num?)?.toDouble(),
      assignedToUserId: (json['assignedToUserId'] as num?)?.toInt(),
      reportedByUserId: (json['reportedByUserId'] as num).toInt(),
      resolutionNotes: json['resolutionNotes'] as String?,
      category: json['category'] as String?,
      requiresInspection: json['requiresInspection'] as bool,
      isTenantComplaint: json['isTenantComplaint'] as bool,
      imageIds: (json['imageIds'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      tenantId: (json['tenantId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MaintenanceIssueToJson(MaintenanceIssue instance) =>
    <String, dynamic>{
      'maintenanceIssueId': instance.maintenanceIssueId,
      'propertyId': instance.propertyId,
      'title': instance.title,
      'description': instance.description,
      'priority': const IssuePriorityConverter().toJson(instance.priority),
      'status': const IssueStatusConverter().toJson(instance.status),
      'resolvedAt': instance.resolvedAt?.toIso8601String(),
      'cost': instance.cost,
      'assignedToUserId': instance.assignedToUserId,
      'reportedByUserId': instance.reportedByUserId,
      'resolutionNotes': instance.resolutionNotes,
      'category': instance.category,
      'requiresInspection': instance.requiresInspection,
      'isTenantComplaint': instance.isTenantComplaint,
      'imageIds': instance.imageIds,
      'createdAt': instance.createdAt.toIso8601String(),
      'tenantId': instance.tenantId,
    };
