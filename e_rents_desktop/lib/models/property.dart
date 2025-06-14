import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import './address.dart';

enum PropertyStatus { available, rented, maintenance, unavailable }

enum PropertyType { apartment, house, condo, townhouse, studio }

class Property {
  final int propertyId;
  final int ownerId;
  final String name;
  final String description;
  final PropertyType type;
  final double price;
  final RentingType rentingType;
  final PropertyStatus status;
  final List<int> imageIds;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final List<MaintenanceIssue> maintenanceIssues;
  final List<int> amenityIds;
  final String currency;
  final int? minimumStayDays;
  final DateTime dateAdded;
  final Address? address;

  // Fields from other entities - use "EntityName + FieldName" pattern
  final String? propertyTypeName;
  final String? rentingTypeName;
  final String? userFirstName; // Owner's first name
  final String? userLastName; // Owner's last name
  final double? averageRating; // Computed from reviews

  Property({
    required this.propertyId,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.type,
    required this.price,
    required this.rentingType,
    required this.status,
    required this.imageIds,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.maintenanceIssues,
    required this.amenityIds,
    this.currency = "BAM",
    this.minimumStayDays,
    required this.dateAdded,
    this.address,
    this.propertyTypeName,
    this.rentingTypeName,
    this.userFirstName,
    this.userLastName,
    this.averageRating,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    print('Property.fromJson: Parsing property data: ${json.keys.toList()}');

    return Property(
      // Handle both propertyId and id field names from backend
      propertyId: json['propertyId'] as int? ?? json['id'] as int? ?? 0,
      ownerId: json['ownerId'] as int? ?? 0,
      // Handle both name and title field names
      name: json['name'] as String? ?? json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      // Prefer display names, fallback to ID conversion
      type: _parsePropertyType(
        json['propertyTypeName'] ??
            json['type'] ??
            json['propertyType'] ??
            json['propertyTypeId'],
      ),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      rentingType: _parseRentingType(
        json['rentingTypeName'] ?? json['rentingType'] ?? json['rentingTypeId'],
      ),
      // ✅ DOMAIN-ALIGNED: Backend now sends string status directly
      status: _parsePropertyStatus(json['status']),
      imageIds: _parseImageIds(json['imageIds']),
      bedrooms: json['bedrooms'] as int? ?? 0,
      bathrooms: json['bathrooms'] as int? ?? 0,
      area: (json['area'] as num?)?.toDouble() ?? 0.0,
      maintenanceIssues: _parseMaintenanceIssues(json['maintenanceIssues']),
      amenityIds: _parseAmenityIds(json['amenityIds']),
      currency: json['currency'] as String? ?? "BAM",
      minimumStayDays: json['minimumStayDays'] as int?,
      // Handle date field name differences
      dateAdded:
          json['dateAdded'] != null
              ? DateTime.parse(json['dateAdded'] as String)
              : (json['createdAt'] != null
                  ? DateTime.parse(json['createdAt'] as String)
                  : DateTime.now()),
      address:
          json['address'] != null
              ? Address.fromJson(json['address'] as Map<String, dynamic>)
              : null,
      // Fields from other entities - use "EntityName + FieldName" pattern
      propertyTypeName: json['propertyTypeName'] as String?,
      rentingTypeName: json['rentingTypeName'] as String?,
      userFirstName: json['userFirstName'] as String?,
      userLastName: json['userLastName'] as String?,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
    );
  }

  static PropertyType _parsePropertyType(dynamic typeValue) {
    if (typeValue == null) return PropertyType.apartment;

    // Handle numeric IDs from backend
    if (typeValue is int) {
      switch (typeValue) {
        case 1:
          return PropertyType.apartment;
        case 2:
          return PropertyType.house;
        case 3:
          return PropertyType.condo;
        case 4:
          return PropertyType.townhouse;
        case 5:
          return PropertyType.studio;
        default:
          return PropertyType.apartment;
      }
    }

    // Handle string values
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

    // Handle numeric IDs from backend
    if (rentingTypeValue is int) {
      switch (rentingTypeValue) {
        case 1:
          return RentingType.monthly;
        case 2:
          return RentingType.daily;
        default:
          return RentingType.monthly;
      }
    }

    // Handle string values
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

    // Handle numeric IDs from backend
    if (statusValue is int) {
      switch (statusValue) {
        case 1:
          return PropertyStatus.available;
        case 2:
          return PropertyStatus.rented;
        case 3:
          return PropertyStatus.maintenance;
        case 4:
          return PropertyStatus.unavailable;
        default:
          return PropertyStatus.available;
      }
    }

    // Handle string values
    String statusString = statusValue.toString().toLowerCase();
    switch (statusString) {
      case 'available':
        return PropertyStatus.available;
      case 'rented':
        return PropertyStatus.rented;
      case 'maintenance':
      case 'undermaintenance':
        return PropertyStatus.maintenance;
      case 'unavailable':
        return PropertyStatus.unavailable;
      default:
        return PropertyStatus.available;
    }
  }

  static List<int> _parseImageIds(dynamic imageIdsValue) {
    if (imageIdsValue == null) return [];

    try {
      if (imageIdsValue is List) {
        return imageIdsValue
            .map((id) => id is int ? id : int.tryParse(id.toString()) ?? 0)
            .where((id) => id > 0)
            .toList();
      }
      return [];
    } catch (e) {
      print('Error parsing imageIds: $e');
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

  static List<int> _parseAmenityIds(dynamic amenityIdsValue) {
    if (amenityIdsValue == null) return [];

    try {
      if (amenityIdsValue is List) {
        return amenityIdsValue
            .map((id) => id is int ? id : int.tryParse(id.toString()) ?? 0)
            .where((id) => id > 0)
            .toList();
      }
      return [];
    } catch (e) {
      print('Error parsing amenityIds: $e');
      return [];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'propertyId': propertyId,
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'price': price,
      'rentingType': rentingType.name,
      'status': status.toString().split('.').last,
      'imageIds': imageIds,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'currency': currency,
      'minimumStayDays': minimumStayDays,
      'dateAdded': dateAdded.toIso8601String(),
      'address': address?.toJson(),
      'amenityIds': amenityIds,
    };
  }

  Property copyWith({
    int? propertyId,
    int? ownerId,
    String? name,
    String? description,
    PropertyType? type,
    double? price,
    RentingType? rentingType,
    PropertyStatus? status,
    List<int>? imageIds,
    int? bedrooms,
    int? bathrooms,
    double? area,
    List<MaintenanceIssue>? maintenanceIssues,
    List<int>? amenityIds,
    String? currency,
    int? minimumStayDays,
    DateTime? dateAdded,
    Address? address,
  }) {
    return Property(
      propertyId: propertyId ?? this.propertyId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      price: price ?? this.price,
      rentingType: rentingType ?? this.rentingType,
      status: status ?? this.status,
      imageIds: imageIds ?? this.imageIds,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      area: area ?? this.area,
      maintenanceIssues: maintenanceIssues ?? this.maintenanceIssues,
      amenityIds: amenityIds ?? this.amenityIds,
      currency: currency ?? this.currency,
      minimumStayDays: minimumStayDays ?? this.minimumStayDays,
      dateAdded: dateAdded ?? this.dateAdded,
      address: address ?? this.address,
    );
  }

  factory Property.empty() => Property(
    propertyId: 0,
    ownerId: 0,
    name: 'N/A',
    description: '',
    type: PropertyType.apartment,
    price: 0.0,
    rentingType: RentingType.monthly,
    status: PropertyStatus.available,
    imageIds: [],
    bedrooms: 0,
    bathrooms: 0,
    area: 0.0,
    maintenanceIssues: [],
    amenityIds: [],
    dateAdded: DateTime.now(),
    address: null,
  );

  // Computed properties for UI convenience (for backward compatibility)
  String? get ownerName =>
      !((userFirstName?.isEmpty ?? true) && (userLastName?.isEmpty ?? true))
          ? '${userFirstName ?? ''} ${userLastName ?? ''}'.trim()
          : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Property &&
          runtimeType == other.runtimeType &&
          propertyId == other.propertyId;

  @override
  int get hashCode => propertyId.hashCode;

  @override
  String toString() {
    return 'Property(id: $propertyId, name: $name, status: $status, price: $price)';
  }
}
