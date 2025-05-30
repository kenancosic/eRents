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
    required this.dateAdded,
    this.addressDetailId,
    this.addressDetail,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['propertyId']?.toString() ?? json['id']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? '',
      title: json['name'] as String? ?? json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: _parsePropertyType(json['type']),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      rentingType: _parseRentingType(json['rentingType']),
      status: _parsePropertyStatus(json['status']),
      images: _parseImages(json['images']),
      bedrooms: json['bedrooms'] as int? ?? 0,
      bathrooms: json['bathrooms'] as int? ?? 0,
      area: (json['area'] as num?)?.toDouble() ?? 0.0,
      maintenanceIssues: _parseMaintenanceIssues(json['maintenanceIssues']),
      amenities: _parseAmenities(json['amenities']),
      currency: json['currency'] as String? ?? "BAM",
      dailyRate: (json['dailyRate'] as num?)?.toDouble(),
      minimumStayDays: json['minimumStayDays'] as int?,
      dateAdded:
          json['dateAdded'] != null
              ? DateTime.parse(json['dateAdded'] as String)
              : DateTime.now(),
      addressDetailId: json['addressDetailId']?.toString(),
      addressDetail:
          json['addressDetail'] != null
              ? AddressDetail.fromJson(
                json['addressDetail'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  static PropertyType _parsePropertyType(dynamic typeValue) {
    if (typeValue == null) return PropertyType.apartment;

    String typeString = typeValue.toString().toLowerCase();
    switch (typeString) {
      case 'apartment':
        return PropertyType.apartment;
      case 'house':
        return PropertyType.house;
      case 'condo':
        return PropertyType.condo;
      case 'townhouse':
        return PropertyType.townhouse;
      case 'studio':
        return PropertyType.studio;
      default:
        return PropertyType.apartment;
    }
  }

  static RentingType _parseRentingType(dynamic rentingTypeValue) {
    if (rentingTypeValue == null) return RentingType.monthly;

    String rentingTypeString = rentingTypeValue.toString().toLowerCase();
    switch (rentingTypeString) {
      case 'daily':
        return RentingType.daily;
      case 'monthly':
        return RentingType.monthly;
      default:
        return RentingType.monthly;
    }
  }

  static PropertyStatus _parsePropertyStatus(dynamic statusValue) {
    if (statusValue == null) return PropertyStatus.available;

    String statusString = statusValue.toString().toLowerCase();
    switch (statusString) {
      case 'available':
        return PropertyStatus.available;
      case 'rented':
        return PropertyStatus.rented;
      case 'maintenance':
        return PropertyStatus.maintenance;
      case 'unavailable':
        return PropertyStatus.unavailable;
      default:
        return PropertyStatus.available;
    }
  }

  static List<erents.ImageInfo> _parseImages(dynamic imagesValue) {
    if (imagesValue == null) return [];

    try {
      final List<dynamic> imagesList = imagesValue as List;
      return imagesList.map((e) {
        if (e is String) {
          return erents.ImageInfo(id: e, url: e);
        } else if (e is Map<String, dynamic>) {
          return erents.ImageInfo.fromJson(e);
        } else {
          return erents.ImageInfo(id: '', url: '');
        }
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static List<MaintenanceIssue> _parseMaintenanceIssues(
    dynamic maintenanceValue,
  ) {
    if (maintenanceValue == null) return [];

    try {
      final List<dynamic> maintenanceList = maintenanceValue as List;
      return maintenanceList
          .map((e) => MaintenanceIssue.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static List<String>? _parseAmenities(dynamic amenitiesValue) {
    if (amenitiesValue == null) return null;

    try {
      if (amenitiesValue is List) {
        // Handle list of amenity objects or strings
        return amenitiesValue
            .map((amenity) {
              if (amenity is String) {
                return amenity;
              } else if (amenity is Map<String, dynamic>) {
                return amenity['name']?.toString() ??
                    amenity['amenityName']?.toString() ??
                    '';
              } else {
                return amenity.toString();
              }
            })
            .where((name) => name.isNotEmpty)
            .toList()
            .cast<String>();
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'propertyId': id.isNotEmpty ? int.tryParse(id) : null,
      'ownerId': ownerId.isNotEmpty ? int.tryParse(ownerId) : null,
      'name': title,
      'description': description,
      'type': type.toString().split('.').last,
      'price': price,
      'rentingType': rentingType.name,
      'status': status.toString().split('.').last,
      'images': images.map((e) => e.toJson()).toList(),
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'currency': currency,
      'dailyRate': dailyRate,
      'minimumStayDays': minimumStayDays,
      'dateAdded': dateAdded.toIso8601String(),
      'addressDetail': addressDetail?.toJson(),
      'amenities': amenities,
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
