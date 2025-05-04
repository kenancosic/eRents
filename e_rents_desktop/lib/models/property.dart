import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/models/renting_type.dart';

class Property {
  final String id;
  final String title;
  final String description;
  final String type;
  final double price;
  final RentingType rentingType;
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
  final double? latitude;
  final double? longitude;
  final String? streetNumber;
  final String? streetName;
  final String? city;
  final String? postalCode;
  final String? country;

  Property({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.price,
    required this.rentingType,
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
    this.latitude,
    this.longitude,
    this.streetNumber,
    this.streetName,
    this.city,
    this.postalCode,
    this.country,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      rentingType: RentingType.values.firstWhere(
        (e) => e.name == json['rentingType'],
        orElse: () => RentingType.monthly,
      ),
      status: json['status'] as String? ?? '',
      images: List<String>.from(json['images'] as List? ?? []),
      address: json['address'] as String? ?? '',
      bedrooms: json['bedrooms'] as int? ?? 0,
      bathrooms: json['bathrooms'] as int? ?? 0,
      area: (json['area'] as num?)?.toDouble() ?? 0.0,
      maintenanceIssues:
          (json['maintenanceIssues'] as List? ?? [])
              .map((e) => MaintenanceIssue.fromJson(e as Map<String, dynamic>))
              .toList(),
      yearBuilt: json['yearBuilt'] as int?,
      amenities:
          json['amenities'] != null
              ? List<String>.from(json['amenities'] as List)
              : null,
      lastInspectionDate:
          json['lastInspectionDate'] != null
              ? DateTime.tryParse(json['lastInspectionDate'] as String? ?? '')
              : null,
      nextInspectionDate:
          json['nextInspectionDate'] != null
              ? DateTime.tryParse(json['nextInspectionDate'] as String? ?? '')
              : null,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      streetNumber: json['streetNumber'] as String?,
      streetName: json['streetName'] as String?,
      city: json['city'] as String?,
      postalCode: json['postalCode'] as String?,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'price': price,
      'rentingType': rentingType.name,
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
      'latitude': latitude,
      'longitude': longitude,
      'streetNumber': streetNumber,
      'streetName': streetName,
      'city': city,
      'postalCode': postalCode,
      'country': country,
    };
  }

  Property copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    double? price,
    RentingType? rentingType,
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
    double? latitude,
    double? longitude,
    String? streetNumber,
    String? streetName,
    String? city,
    String? postalCode,
    String? country,
  }) {
    return Property(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      price: price ?? this.price,
      rentingType: rentingType ?? this.rentingType,
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
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      streetNumber: streetNumber ?? this.streetNumber,
      streetName: streetName ?? this.streetName,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
    );
  }

  factory Property.empty() => Property(
    id: '',
    title: 'N/A',
    description: '',
    type: '',
    price: 0.0,
    rentingType: RentingType.monthly,
    status: '',
    images: [],
    address: '',
    bedrooms: 0,
    bathrooms: 0,
    area: 0.0,
    maintenanceIssues: [],
    latitude: null,
    longitude: null,
    streetNumber: null,
    streetName: null,
    city: null,
    postalCode: null,
    country: null,
  );
}
