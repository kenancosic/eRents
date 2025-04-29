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
  final List<MaintenanceIssue> maintenanceIssues;
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
    required this.maintenanceIssues,
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
      maintenanceIssues:
          (json['maintenanceIssues'] as List)
              .map((e) => MaintenanceIssue.fromJson(e as Map<String, dynamic>))
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
      'maintenanceIssues': maintenanceIssues.map((e) => e.toJson()).toList(),
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
    List<MaintenanceIssue>? maintenanceIssues,
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
      maintenanceIssues: maintenanceIssues ?? this.maintenanceIssues,
      yearBuilt: yearBuilt ?? this.yearBuilt,
      amenities: amenities ?? this.amenities,
      lastInspectionDate: lastInspectionDate ?? this.lastInspectionDate,
      nextInspectionDate: nextInspectionDate ?? this.nextInspectionDate,
    );
  }

  factory Property.empty() => Property(
    id: '',
    title: 'N/A', // Or 'Unknown Property'
    description: '',
    type: '',
    price: 0.0,
    status: '',
    images: [],
    address: '',
    bedrooms: 0,
    bathrooms: 0,
    area: 0.0,
    maintenanceIssues: [],
    // Add any other required fields with default values
  );
}
