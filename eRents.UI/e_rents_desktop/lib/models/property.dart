import 'package:e_rents_desktop/models/maintenance_issue.dart';

class Property {
  final String id;
  final String title;
  final String description;
  final String type;
  final double price;
  final String status;
  final List<String> images;
  final String address;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final List<MaintenanceRequest> maintenanceRequests;
  final int? yearBuilt;
  final List<String>? amenities;
  final DateTime? lastInspectionDate;
  final DateTime? nextInspectionDate;

  Property({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.price,
    required this.status,
    required this.images,
    required this.address,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.maintenanceRequests,
    this.yearBuilt,
    this.amenities,
    this.lastInspectionDate,
    this.nextInspectionDate,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      price: (json['price'] as num).toDouble(),
      status: json['status'] as String,
      images: List<String>.from(json['images'] as List),
      address: json['address'] as String,
      bedrooms: json['bedrooms'] as int,
      bathrooms: json['bathrooms'] as int,
      area: (json['area'] as num).toDouble(),
      maintenanceRequests:
          (json['maintenanceRequests'] as List)
              .map(
                (e) => MaintenanceRequest.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      yearBuilt: json['yearBuilt'] as int?,
      amenities:
          json['amenities'] != null
              ? List<String>.from(json['amenities'] as List)
              : null,
      lastInspectionDate:
          json['lastInspectionDate'] != null
              ? DateTime.parse(json['lastInspectionDate'] as String)
              : null,
      nextInspectionDate:
          json['nextInspectionDate'] != null
              ? DateTime.parse(json['nextInspectionDate'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'price': price,
      'status': status,
      'images': images,
      'address': address,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'maintenanceRequests':
          maintenanceRequests.map((e) => e.toJson()).toList(),
      'yearBuilt': yearBuilt,
      'amenities': amenities,
      'lastInspectionDate': lastInspectionDate?.toIso8601String(),
      'nextInspectionDate': nextInspectionDate?.toIso8601String(),
    };
  }

  Property copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    double? price,
    String? status,
    List<String>? images,
    String? address,
    int? bedrooms,
    int? bathrooms,
    double? area,
    List<MaintenanceRequest>? maintenanceRequests,
    int? yearBuilt,
    List<String>? amenities,
    DateTime? lastInspectionDate,
    DateTime? nextInspectionDate,
  }) {
    return Property(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      price: price ?? this.price,
      status: status ?? this.status,
      images: images ?? this.images,
      address: address ?? this.address,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      area: area ?? this.area,
      maintenanceRequests: maintenanceRequests ?? this.maintenanceRequests,
      yearBuilt: yearBuilt ?? this.yearBuilt,
      amenities: amenities ?? this.amenities,
      lastInspectionDate: lastInspectionDate ?? this.lastInspectionDate,
      nextInspectionDate: nextInspectionDate ?? this.nextInspectionDate,
    );
  }
}

class MaintenanceRequest {
  final String id;
  final String title;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? category;
  final String? priority;
  final String? assignedTo;
  final String? reportedBy;

  MaintenanceRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.category,
    this.priority,
    this.assignedTo,
    this.reportedBy,
  });

  factory MaintenanceRequest.fromMaintenanceIssue(MaintenanceIssue issue) {
    return MaintenanceRequest(
      id: issue.id,
      title: issue.title,
      description: issue.description,
      status: issue.status.toString().split('.').last,
      createdAt: issue.createdAt,
      completedAt: issue.resolvedAt,
      category: issue.category,
      priority: issue.priority.toString().split('.').last,
      assignedTo: issue.assignedTo,
      reportedBy: issue.reportedBy,
    );
  }

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) {
    return MaintenanceRequest(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt:
          json['completedAt'] != null
              ? DateTime.parse(json['completedAt'] as String)
              : null,
      category: json['category'] as String?,
      priority: json['priority'] as String?,
      assignedTo: json['assignedTo'] as String?,
      reportedBy: json['reportedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'category': category,
      'priority': priority,
      'assignedTo': assignedTo,
      'reportedBy': reportedBy,
    };
  }
}
