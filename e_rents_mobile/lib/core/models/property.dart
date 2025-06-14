import './address.dart';

enum PropertyRentalType {
  daily, // Short-term daily rentals (hotels, vacation rentals)
  monthly // Long-term monthly leases with minimum stays
}

enum PropertyType { apartment, house, condo, townhouse, studio }

enum PropertyStatus { available, rented, maintenance, unavailable }

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
  final PropertyRentalType rentalType;
  final PropertyType? propertyType;
  final int? bedrooms;
  final int? bathrooms;
  final double? area;
  final double? dailyRate;
  final int? minimumStayDays;
  final int? propertyTypeId;
  final int? rentingTypeId;

  Property({
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
    required this.imageIds,
    required this.amenityIds,
    this.address,
    this.rentalType = PropertyRentalType.monthly,
    this.propertyType,
    this.bedrooms,
    this.bathrooms,
    this.area,
    this.dailyRate,
    this.minimumStayDays,
    this.propertyTypeId,
    this.rentingTypeId,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      propertyId: json['propertyId'] ?? json['id'] ?? 0,
      ownerId: json['ownerId'] ?? 0,
      description: json['description'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? "BAM",
      facilities: json['facilities'],
      status: json['status'] != null
          ? PropertyStatus.values.firstWhere(
              (e) => e.toString().split('.').last == json['status'],
              orElse: () => PropertyStatus.available,
            )
          : PropertyStatus.available,
      dateAdded:
          json['dateAdded'] != null ? DateTime.parse(json['dateAdded']) : null,
      name: json['name'] ?? '',
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      imageIds: _parseImageIds(json['imageIds']),
      amenityIds: _parseAmenityIds(json['amenityIds']),
      address: json['addressDetail'] != null
          ? Address.fromJson(json['addressDetail'] as Map<String, dynamic>)
          : null,
      rentalType: json['rentalType'] != null
          ? PropertyRentalType.values.firstWhere(
              (e) => e.toString().split('.').last == json['rentalType'],
              orElse: () => PropertyRentalType.monthly,
            )
          : PropertyRentalType.monthly,
      propertyType: json['propertyType'] != null
          ? PropertyType.values.firstWhere(
              (e) => e.toString().split('.').last == json['propertyType'],
              orElse: () => PropertyType.apartment,
            )
          : null,
      bedrooms: json['bedrooms'] as int?,
      bathrooms: json['bathrooms'] as int?,
      area: (json['area'] as num?)?.toDouble(),
      dailyRate: (json['dailyRate'] as num?)?.toDouble(),
      minimumStayDays: json['minimumStayDays'] as int?,
      propertyTypeId: json['propertyTypeId'] as int?,
      rentingTypeId: json['rentingTypeId'] as int?,
    );
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
      'description': description,
      'price': price,
      'currency': currency,
      'facilities': facilities,
      'status': status.toString().split('.').last,
      'dateAdded': dateAdded?.toIso8601String(),
      'name': name,
      'averageRating': averageRating,
      'imageIds': imageIds,
      'amenityIds': amenityIds,
      'addressDetail': address?.toAddressDetailJson(),
      'rentalType': rentalType.toString().split('.').last,
      'propertyType': propertyType?.toString().split('.').last,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'dailyRate': dailyRate,
      'minimumStayDays': minimumStayDays,
      'propertyTypeId': propertyTypeId,
      'rentingTypeId': rentingTypeId,
    };
  }
}
