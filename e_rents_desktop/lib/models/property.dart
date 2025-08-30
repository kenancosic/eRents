import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/models/enums/property_status.dart';
import 'package:e_rents_desktop/models/enums/property_type.dart';
import 'package:e_rents_desktop/models/enums/renting_type.dart';

class Property {
  final int propertyId;
  final int ownerId;
  final String? description;
  final double price;
  final String currency;
  final String? facilities;
  final PropertyStatus status;
  final DateTime? dateAdded;
  final String name;
  final double? averageRating;
  final List<int> imageIds;
  final List<int> amenityIds;
  final Address? address;
  final PropertyType? propertyType;
  final RentingType? rentingType;
  final int? rooms;
  final double? area;
  final int? minimumStayDays;
  final bool requiresApproval;
  final DateTime? unavailableFrom;
  final DateTime? unavailableTo;
  final int? coverImageId;

  const Property({
    required this.propertyId,
    required this.ownerId,
    this.description,
    required this.price,
    this.currency = "BAM",
    this.facilities,
    this.status = PropertyStatus.available,
    this.dateAdded,
    required this.name,
    this.averageRating,
    this.imageIds = const [],
    this.amenityIds = const [],
    this.address,
    this.propertyType,
    this.rentingType,
    this.rooms,
    this.area,
    this.minimumStayDays,
    this.requiresApproval = false,
    this.unavailableFrom,
    this.unavailableTo,
    this.coverImageId,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) => v is num ? v.toDouble() : double.parse(v.toString());
    List<int> _toIntList(dynamic v) {
      if (v == null) return const [];
      if (v is List) {
        return v.map((e) => (e as num).toInt()).toList();
      }
      return const [];
    }
    return Property(
      propertyId: (json['propertyId'] as num).toInt(),
      ownerId: (json['ownerId'] as num).toInt(),
      description: json['description'] as String?,
      price: _toDouble(json['price']),
      currency: (json['currency'] as String?) ?? 'BAM',
      facilities: json['facilities'] as String?,
      status: json['status'] == null ? PropertyStatus.available : Property._statusFromJson(json['status']),
      dateAdded: json['dateAdded'] == null ? null : DateTime.tryParse(json['dateAdded'] as String),
      name: json['name'] as String,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      imageIds: _toIntList(json['imageIds']),
      amenityIds: _toIntList(json['amenityIds']),
      address: json['address'] == null ? null : Address.fromJson(json['address'] as Map<String, dynamic>),
      propertyType: json['propertyType'] == null ? null : Property._propertyTypeFromJson(json['propertyType']),
      rentingType: json['rentingType'] == null ? null : Property._rentingTypeFromJson(json['rentingType']),
      rooms: (json['rooms'] as num?)?.toInt(),
      area: (json['area'] as num?)?.toDouble(),
      minimumStayDays: (json['minimumStayDays'] as num?)?.toInt(),
      requiresApproval: (json['requiresApproval'] as bool?) ?? false,
      unavailableFrom: json['unavailableFrom'] == null ? null : DateTime.tryParse(json['unavailableFrom'] as String),
      unavailableTo: json['unavailableTo'] == null ? null : DateTime.tryParse(json['unavailableTo'] as String),
      coverImageId: (json['coverImageId'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'propertyId': propertyId,
        'ownerId': ownerId,
        'description': description,
        'price': price,
        'currency': currency,
        'facilities': facilities,
        'status': Property._statusToJson(status),
        'dateAdded': dateAdded?.toIso8601String(),
        'name': name,
        'averageRating': averageRating,
        'imageIds': imageIds,
        'amenityIds': amenityIds,
        'address': address?.toJson(),
        'propertyType': Property._propertyTypeToJson(propertyType),
        'rentingType': Property._rentingTypeToJson(rentingType),
        'rooms': rooms,
        'area': area,
        'minimumStayDays': minimumStayDays,
        'requiresApproval': requiresApproval,
        'unavailableFrom': unavailableFrom?.toIso8601String(),
        'unavailableTo': unavailableTo?.toIso8601String(),
        'coverImageId': coverImageId,
      };

  // Payload for POST/PUT requests to backend PropertyRequest (flattened address)
  Map<String, dynamic> toRequestJson() => <String, dynamic>{
        'name': name,
        'description': description,
        'price': price,
        'currency': currency,
        'rooms': rooms,
        'area': area,
        'minimumStayDays': minimumStayDays,
        'requiresApproval': requiresApproval,
        'unavailableFrom': unavailableFrom?.toIso8601String(),
        'unavailableTo': unavailableTo?.toIso8601String(),
        // Backend expects enum numeric codes
        'propertyType': Property._propertyTypeToRequest(propertyType),
        'rentingType': Property._rentingTypeToRequest(rentingType),
        'status': Property._statusToRequest(status),
        // Flattened address
        'streetLine1': address?.streetLine1,
        'streetLine2': address?.streetLine2,
        'city': address?.city,
        'state': address?.state,
        'country': address?.country,
        'postalCode': address?.postalCode,
        'latitude': address?.latitude,
        'longitude': address?.longitude,
      }..removeWhere((k, v) => v == null);

  // Legacy compatibility getters
  int? get propertyTypeId => propertyType?.index;
  int? get rentingTypeId => rentingType?.index;

  // Custom enum decoding/encoding to support backend sending either int codes or strings
  static PropertyStatus _statusFromJson(dynamic value) {
    if (value == null) return PropertyStatus.available;
    if (value is int) {
      try {
        return PropertyStatus.fromValue(value);
      } catch (_) {
        return PropertyStatus.available;
      }
    }
    if (value is String) {
      try {
        return PropertyStatus.fromString(value);
      } catch (_) {
        // try parse numeric string
        final asInt = int.tryParse(value);
        if (asInt != null) {
          try {
            return PropertyStatus.fromValue(asInt);
          } catch (_) {}
        }
        return PropertyStatus.available;
      }
    }
    return PropertyStatus.available;
  }

  static PropertyType _propertyTypeFromJson(dynamic value) {
    if (value == null) return PropertyType.apartment;
    if (value is int) {
      try {
        return PropertyType.fromValue(value);
      } catch (_) {
        return PropertyType.apartment;
      }
    }
    if (value is String) {
      try {
        return PropertyType.fromString(value);
      } catch (_) {
        // try parse numeric string
        final asInt = int.tryParse(value);
        if (asInt != null) {
          try {
            return PropertyType.fromValue(asInt);
          } catch (_) {}
        }
        return PropertyType.apartment;
      }
    }
    return PropertyType.apartment;
  }

  static RentingType _rentingTypeFromJson(dynamic value) {
    if (value == null) return RentingType.daily;
    if (value is int) {
      try {
        return RentingType.fromValue(value);
      } catch (_) {
        return RentingType.daily;
      }
    }
    if (value is String) {
      try {
        return RentingType.fromString(value);
      } catch (_) {
        // try parse numeric string
        final asInt = int.tryParse(value);
        if (asInt != null) {
          try {
            return RentingType.fromValue(asInt);
          } catch (_) {}
        }
        return RentingType.daily;
      }
    }
    return RentingType.daily;
  }

  static String _statusToJson(PropertyStatus status) => status.name;
  static int _statusToRequest(PropertyStatus status) => status.value;

  static String? _propertyTypeToJson(PropertyType? type) => type?.name;
  static int? _propertyTypeToRequest(PropertyType? type) => type?.value;

  static String? _rentingTypeToJson(RentingType? type) => type?.name;
  static int? _rentingTypeToRequest(RentingType? type) => type?.value;
}