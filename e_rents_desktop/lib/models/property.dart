import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import './address_detail.dart';
import 'package:e_rents_desktop/models/image_info.dart' as erents;

enum PropertyStatus { available, rented, maintenance, unavailable }

enum PropertyType { apartment, house, condo, townhouse, studio }

class Property {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final PropertyType type;
  final double price;
  final RentingType rentingType;
  final PropertyStatus status;
  final List<erents.ImageInfo> images;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final List<MaintenanceIssue> maintenanceIssues;
  final List<String>? amenities;
  final String currency; // Added for standardization
  final double? dailyRate; // Added mobile-specific field
  final int? minimumStayDays; // Added mobile-specific field
  final DateTime? lastInspectionDate;
  final DateTime? nextInspectionDate;
  final DateTime dateAdded;
  final String? addressDetailId;
  final AddressDetail? addressDetail;

  Property({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.type,
    required this.price,
    required this.rentingType,
    required this.status,
    required this.images,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.maintenanceIssues,
    this.amenities,
    this.currency = "BAM",
    this.dailyRate,
    this.minimumStayDays,
    this.lastInspectionDate,
    this.nextInspectionDate,
    required this.dateAdded,
    this.addressDetailId,
    this.addressDetail,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as String? ?? json['propertyId']?.toString() ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: PropertyType.values.firstWhere(
        (e) => e.toString() == 'PropertyType.${json['type']}',
        orElse: () => PropertyType.apartment,
      ),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      rentingType: RentingType.values.firstWhere(
        (e) => e.name == json['rentingType'],
        orElse: () => RentingType.monthly,
      ),
      status: PropertyStatus.values.firstWhere(
        (e) => e.toString() == 'PropertyStatus.${json['status']}',
        orElse: () => PropertyStatus.available,
      ),
      images:
          (json['images'] as List? ?? [])
              .map(
                (e) =>
                    e is String
                        ? erents.ImageInfo(id: e, url: e)
                        : erents.ImageInfo.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      bedrooms: json['bedrooms'] as int? ?? 0,
      bathrooms: json['bathrooms'] as int? ?? 0,
      area: (json['area'] as num?)?.toDouble() ?? 0.0,
      maintenanceIssues:
          (json['maintenanceIssues'] as List? ?? [])
              .map((e) => MaintenanceIssue.fromJson(e as Map<String, dynamic>))
              .toList(),
      amenities:
          json['amenities'] != null
              ? List<String>.from(json['amenities'] as List)
              : null,
      currency: json['currency'] as String? ?? "BAM",
      dailyRate: (json['dailyRate'] as num?)?.toDouble(),
      minimumStayDays: json['minimumStayDays'] as int?,
      lastInspectionDate:
          json['lastInspectionDate'] != null
              ? DateTime.tryParse(json['lastInspectionDate'] as String? ?? '')
              : null,
      nextInspectionDate:
          json['nextInspectionDate'] != null
              ? DateTime.tryParse(json['nextInspectionDate'] as String? ?? '')
              : null,
      dateAdded: DateTime.parse(
        json['dateAdded'] as String? ?? DateTime.now().toIso8601String(),
      ),
      addressDetailId: json['addressDetailId']?.toString(),
      addressDetail:
          json['addressDetail'] != null
              ? AddressDetail.fromJson(
                json['addressDetail'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'price': price,
      'rentingType': rentingType.name,
      'status': status.toString().split('.').last,
      'images': images.map((e) => e.toJson()).toList(),
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'maintenanceIssues': maintenanceIssues.map((e) => e.toJson()).toList(),
      'amenities': amenities,
      'currency': currency,
      'dailyRate': dailyRate,
      'minimumStayDays': minimumStayDays,
      'lastInspectionDate': lastInspectionDate?.toIso8601String(),
      'nextInspectionDate': nextInspectionDate?.toIso8601String(),
      'dateAdded': dateAdded.toIso8601String(),
      'addressDetailId': addressDetailId,
      'addressDetail': addressDetail?.toJson(),
    };
  }

  Property copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    PropertyType? type,
    double? price,
    RentingType? rentingType,
    PropertyStatus? status,
    List<erents.ImageInfo>? images,
    int? bedrooms,
    int? bathrooms,
    double? area,
    List<MaintenanceIssue>? maintenanceIssues,
    List<String>? amenities,
    String? currency,
    double? dailyRate,
    int? minimumStayDays,
    DateTime? lastInspectionDate,
    DateTime? nextInspectionDate,
    DateTime? dateAdded,
    String? addressDetailId,
    AddressDetail? addressDetail,
  }) {
    return Property(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      price: price ?? this.price,
      rentingType: rentingType ?? this.rentingType,
      status: status ?? this.status,
      images: images ?? this.images,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      area: area ?? this.area,
      maintenanceIssues: maintenanceIssues ?? this.maintenanceIssues,
      amenities: amenities ?? this.amenities,
      currency: currency ?? this.currency,
      dailyRate: dailyRate ?? this.dailyRate,
      minimumStayDays: minimumStayDays ?? this.minimumStayDays,
      lastInspectionDate: lastInspectionDate ?? this.lastInspectionDate,
      nextInspectionDate: nextInspectionDate ?? this.nextInspectionDate,
      dateAdded: dateAdded ?? this.dateAdded,
      addressDetailId: addressDetailId ?? this.addressDetailId,
      addressDetail: addressDetail ?? this.addressDetail,
    );
  }

  factory Property.empty() => Property(
    id: '',
    ownerId: '',
    title: 'N/A',
    description: '',
    type: PropertyType.apartment,
    price: 0.0,
    rentingType: RentingType.monthly,
    status: PropertyStatus.available,
    images: [],
    bedrooms: 0,
    bathrooms: 0,
    area: 0.0,
    maintenanceIssues: [],
    dateAdded: DateTime.now(),
    addressDetailId: null,
    addressDetail: null,
  );
}
