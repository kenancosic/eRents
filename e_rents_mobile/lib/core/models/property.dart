import 'package:e_rents_mobile/core/models/image_response.dart';
import './address_detail.dart';

enum PropertyRentalType {
  daily, // Short-term daily rentals (hotels, vacation rentals)
  monthly, // Long-term monthly leases with minimum stays
  both // Properties that support both daily and monthly rentals
}

class Property {
  final int propertyId;
  final int ownerId;
  final String? description;
  final double price;
  final String? facilities;
  final String? status;
  final DateTime? dateAdded;
  final String name;
  final double? averageRating;
  final List<ImageResponse> images;
  final int? addressDetailId;
  final AddressDetail? addressDetail;
  final PropertyRentalType rentalType;
  final double? dailyRate; // For daily rentals
  final int? minimumStayDays; // Minimum stay requirement

  Property({
    required this.propertyId,
    required this.ownerId,
    this.description,
    required this.price,
    this.facilities,
    this.status,
    this.dateAdded,
    required this.name,
    this.averageRating,
    required this.images,
    this.addressDetailId,
    this.addressDetail,
    this.rentalType = PropertyRentalType.monthly,
    this.dailyRate,
    this.minimumStayDays,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      propertyId: json['propertyId'],
      ownerId: json['ownerId'],
      description: json['description'],
      price: json['price'].toDouble(),
      facilities: json['facilities'],
      status: json['status'],
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
      'facilities': facilities,
      'status': status,
      'dateAdded': dateAdded?.toIso8601String(),
      'name': name,
      'averageRating': averageRating,
      'images': images.map((i) => i.toJson()).toList(),
      'addressDetailId': addressDetailId,
      'addressDetail': addressDetail?.toJson(),
    };
  }
}
