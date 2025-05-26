import 'package:e_rents_mobile/core/models/image_response.dart';
import './address_detail.dart';

enum PropertyRentalType {
  daily, // Short-term daily rentals (hotels, vacation rentals)
  monthly, // Long-term monthly leases with minimum stays
  both // Properties that support both daily and monthly rentals
}

enum PropertyType { apartment, house, condo, townhouse, studio }

enum PropertyStatus { available, rented, maintenance, unavailable }

class Property {
  final int propertyId;
  final int ownerId;
  final String? description;
  final double price;
  final String currency; // Added for standardization
  final String? facilities;
  final PropertyStatus status; // Changed from String to enum
  final DateTime? dateAdded;
  final String name;
  final double? averageRating;
  final List<ImageResponse> images;
  final int? addressDetailId;
  final AddressDetail? addressDetail;
  final PropertyRentalType rentalType;
  final PropertyType? propertyType; // Added missing field
  final int? bedrooms; // Added missing field
  final int? bathrooms; // Added missing field
  final double? area; // Added missing field
  final double? dailyRate; // For daily rentals
  final int? minimumStayDays; // Minimum stay requirement

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
    required this.images,
    this.addressDetailId,
    this.addressDetail,
    this.rentalType = PropertyRentalType.monthly,
    this.propertyType,
    this.bedrooms,
    this.bathrooms,
    this.area,
    this.dailyRate,
    this.minimumStayDays,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      propertyId: json['propertyId'],
      ownerId: json['ownerId'],
      description: json['description'],
      price: json['price'].toDouble(),
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
      name: json['name'],
      averageRating: json['averageRating']?.toDouble(),
      images: (json['images'] as List)
          .map((i) => ImageResponse.fromJson(i as Map<String, dynamic>))
          .toList(),
      addressDetailId: json['addressDetailId'] as int?,
      addressDetail: json['addressDetail'] != null
          ? AddressDetail.fromJson(
              json['addressDetail'] as Map<String, dynamic>)
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
      area: json['area']?.toDouble(),
      dailyRate: json['dailyRate']?.toDouble(),
      minimumStayDays: json['minimumStayDays'] as int?,
    );
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
      'images': images.map((i) => i.toJson()).toList(),
      'addressDetailId': addressDetailId,
      'addressDetail': addressDetail?.toJson(),
      'rentalType': rentalType.toString().split('.').last,
      'propertyType': propertyType?.toString().split('.').last,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'dailyRate': dailyRate,
      'minimumStayDays': minimumStayDays,
    };
  }
}
