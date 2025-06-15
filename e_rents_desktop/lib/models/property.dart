import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import './address.dart';

/// Property status enum matching backend PropertyStatus values
enum PropertyStatus { available, rented, maintenance, unavailable }

/// Property type enum matching backend PropertyType values
enum PropertyType { apartment, house, condo, townhouse, studio }

/// Property entity model matching the comprehensive analysis
///
/// This model aligns with the PropertyResponse DTO from the backend
/// and includes all fields from the Property table analysis.
class Property {
  // Core identifiers
  final int propertyId;
  final int ownerId;

  // Basic information
  final String name;
  final String description;
  final double price;
  final String currency;
  final String? status; // Raw status from backend for debugging
  final DateTime? dateAdded;

  // Property characteristics
  final int? propertyTypeId;
  final int? rentingTypeId;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final int? minimumStayDays;
  final bool requiresApproval;

  // Embedded value object
  final Address? address;

  // Related data as IDs (frontend fetches full objects when needed)
  final List<int> amenityIds;
  final List<int> imageIds;

  // Computed fields from related entities
  final String? propertyTypeName;
  final String? rentingTypeName;
  final String? userFirstName;
  final String? userLastName;
  final double? averageRating;

  // Relationships (for local data only, not persisted)
  final List<MaintenanceIssue> maintenanceIssues;

  Property({
    required this.propertyId,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.price,
    this.currency = "BAM",
    this.status,
    this.dateAdded,
    this.propertyTypeId,
    this.rentingTypeId,
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.area = 0.0,
    this.minimumStayDays,
    this.requiresApproval = false,
    this.address,
    this.amenityIds = const [],
    this.imageIds = const [],
    this.propertyTypeName,
    this.rentingTypeName,
    this.userFirstName,
    this.userLastName,
    this.averageRating,
    this.maintenanceIssues = const [],
  });

  /// Factory constructor from backend PropertyResponse DTO
  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      // Core identifiers
      propertyId: _parseInt(json['propertyId'] ?? json['id'], 0),
      ownerId: _parseInt(json['ownerId'], 0),

      // Basic information
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: _parseDecimal(json['price'], 0.0),
      currency: json['currency'] as String? ?? "BAM",
      status: json['status'] as String?,
      dateAdded: _parseDateTime(json['dateAdded']),

      // Property characteristics
      propertyTypeId: _parseInt(json['propertyTypeId'], null),
      rentingTypeId: _parseInt(json['rentingTypeId'], null),
      bedrooms: _parseInt(json['bedrooms'], 0),
      bathrooms: _parseInt(json['bathrooms'], 0),
      area: _parseDecimal(json['area'], 0.0),
      minimumStayDays: _parseInt(json['minimumStayDays'], null),
      requiresApproval: json['requiresApproval'] as bool? ?? false,

      // Embedded value object
      address:
          json['address'] != null
              ? Address.fromJson(json['address'] as Map<String, dynamic>)
              : null,

      // Related data as IDs
      amenityIds: _parseIntList(json['amenityIds']),
      imageIds: _parseIntList(json['imageIds']),

      // Computed fields from related entities
      propertyTypeName: json['propertyTypeName'] as String?,
      rentingTypeName: json['rentingTypeName'] as String?,
      userFirstName: json['userFirstName'] as String?,
      userLastName: json['userLastName'] as String?,
      averageRating: _parseDecimal(json['averageRating'], null),

      // Local relationships
      maintenanceIssues: _parseMaintenanceIssues(json['maintenanceIssues']),
    );
  }

  /// Convert to JSON for backend requests
  Map<String, dynamic> toJson() {
    return {
      'propertyId': propertyId,
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'status': status,
      'propertyTypeId': propertyTypeId,
      'rentingTypeId': rentingTypeId,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'minimumStayDays': minimumStayDays,
      'requiresApproval': requiresApproval,
      'address': address?.toJson(),
      'amenityIds': amenityIds,
      'imageIds': imageIds,
      if (dateAdded != null) 'dateAdded': dateAdded!.toIso8601String(),
    };
  }

  /// Create copy with updated fields
  Property copyWith({
    int? propertyId,
    int? ownerId,
    String? name,
    String? description,
    double? price,
    String? currency,
    String? status,
    DateTime? dateAdded,
    int? propertyTypeId,
    int? rentingTypeId,
    int? bedrooms,
    int? bathrooms,
    double? area,
    int? minimumStayDays,
    bool? requiresApproval,
    Address? address,
    List<int>? amenityIds,
    List<int>? imageIds,
    String? propertyTypeName,
    String? rentingTypeName,
    String? userFirstName,
    String? userLastName,
    double? averageRating,
    List<MaintenanceIssue>? maintenanceIssues,
  }) {
    return Property(
      propertyId: propertyId ?? this.propertyId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      dateAdded: dateAdded ?? this.dateAdded,
      propertyTypeId: propertyTypeId ?? this.propertyTypeId,
      rentingTypeId: rentingTypeId ?? this.rentingTypeId,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      area: area ?? this.area,
      minimumStayDays: minimumStayDays ?? this.minimumStayDays,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      address: address ?? this.address,
      amenityIds: amenityIds ?? this.amenityIds,
      imageIds: imageIds ?? this.imageIds,
      propertyTypeName: propertyTypeName ?? this.propertyTypeName,
      rentingTypeName: rentingTypeName ?? this.rentingTypeName,
      userFirstName: userFirstName ?? this.userFirstName,
      userLastName: userLastName ?? this.userLastName,
      averageRating: averageRating ?? this.averageRating,
      maintenanceIssues: maintenanceIssues ?? this.maintenanceIssues,
    );
  }

  /// Empty property factory for initialization
  factory Property.empty() => Property(
    propertyId: 0,
    ownerId: 0,
    name: '',
    description: '',
    price: 0.0,
  );

  // Computed getters for backwards compatibility and UI convenience

  /// Get property type enum from computed field or type ID
  PropertyType get type {
    if (propertyTypeName != null) {
      return _parsePropertyTypeFromName(propertyTypeName!);
    }
    if (propertyTypeId != null) {
      return _parsePropertyTypeFromId(propertyTypeId!);
    }
    return PropertyType.apartment;
  }

  /// Get renting type enum from computed field or type ID
  RentingType get rentingType {
    if (rentingTypeName != null) {
      return _parseRentingTypeFromName(rentingTypeName!);
    }
    if (rentingTypeId != null) {
      return _parseRentingTypeFromId(rentingTypeId!);
    }
    return RentingType.monthly;
  }

  /// Get property status enum from status string
  PropertyStatus get propertyStatus {
    if (status == null) return PropertyStatus.available;
    return _parsePropertyStatusFromString(status!);
  }

  /// Get owner name from user fields
  String? get ownerName {
    if (userFirstName?.isEmpty == false || userLastName?.isEmpty == false) {
      return '${userFirstName ?? ''} ${userLastName ?? ''}'.trim();
    }
    return null;
  }

  /// Check if property has images
  bool get hasImages => imageIds.isNotEmpty;

  /// Check if property has amenities
  bool get hasAmenities => amenityIds.isNotEmpty;

  /// Check if property is available
  bool get isAvailable => propertyStatus == PropertyStatus.available;

  /// Check if property is rented
  bool get isRented => propertyStatus == PropertyStatus.rented;

  /// Check if property is under maintenance
  bool get inMaintenance => propertyStatus == PropertyStatus.maintenance;

  // Helper parsing methods

  static int _parseInt(dynamic value, int? defaultValue) {
    if (value == null) return defaultValue ?? 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? (defaultValue ?? 0);
    return defaultValue ?? 0;
  }

  static double _parseDecimal(dynamic value, double? defaultValue) {
    if (value == null) return defaultValue ?? 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? (defaultValue ?? 0.0);
    return defaultValue ?? 0.0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static List<int> _parseIntList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => _parseInt(e, 0)).where((id) => id > 0).toList();
    }
    return [];
  }

  static List<MaintenanceIssue> _parseMaintenanceIssues(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      try {
        return value
            .map((e) => MaintenanceIssue.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  static PropertyType _parsePropertyTypeFromName(String name) {
    switch (name.toLowerCase()) {
      case 'apartment':
        return PropertyType.apartment;
      case 'house':
        return PropertyType.house;
      case 'condo':
      case 'condominium':
        return PropertyType.condo;
      case 'townhouse':
        return PropertyType.townhouse;
      case 'studio':
        return PropertyType.studio;
      default:
        return PropertyType.apartment;
    }
  }

  static PropertyType _parsePropertyTypeFromId(int id) {
    switch (id) {
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

  static RentingType _parseRentingTypeFromName(String name) {
    switch (name.toLowerCase()) {
      case 'daily':
        return RentingType.daily;
      case 'monthly':
        return RentingType.monthly;
      default:
        return RentingType.monthly;
    }
  }

  static RentingType _parseRentingTypeFromId(int id) {
    switch (id) {
      case 1:
        return RentingType.monthly;
      case 2:
        return RentingType.daily;
      default:
        return RentingType.monthly;
    }
  }

  static PropertyStatus _parsePropertyStatusFromString(String status) {
    switch (status.toLowerCase()) {
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
    return 'Property(id: $propertyId, name: $name, status: $status, price: $price $currency)';
  }
}

/// Extensions for enum display names
extension PropertyStatusExtension on PropertyStatus {
  String get displayName {
    switch (this) {
      case PropertyStatus.available:
        return 'Available';
      case PropertyStatus.rented:
        return 'Rented';
      case PropertyStatus.maintenance:
        return 'Maintenance';
      case PropertyStatus.unavailable:
        return 'Unavailable';
    }
  }
}

extension PropertyTypeExtension on PropertyType {
  String get displayName {
    switch (this) {
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.house:
        return 'House';
      case PropertyType.condo:
        return 'Condominium';
      case PropertyType.townhouse:
        return 'Townhouse';
      case PropertyType.studio:
        return 'Studio';
    }
  }
}
