import 'package:e_rents_mobile/core/models/image_response.dart';

class Property {
  final int propertyId;
  final int ownerId;
  final int cityId;
  final String address;
  final String? city;
  final String? zipCode;
  final String? streetName;
  final String? streetNumber;
  final String? description;
  final double price;
  final String? facilities;
  final String? status;
  final double? latitude;
  final double? longitude;
  final DateTime? dateAdded;
  final String name;
  final double? averageRating;
  final List<ImageResponse> images;

  Property({
    required this.propertyId,
    required this.ownerId,
    required this.cityId,
    required this.address,
    this.city,
    this.zipCode,
    this.streetName,
    this.streetNumber,
    this.description,
    required this.price,
    this.facilities,
    this.status,
    this.latitude,
    this.longitude,
    this.dateAdded,
    required this.name,
    this.averageRating,
    required this.images,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      propertyId: json['propertyId'],
      ownerId: json['ownerId'],
      cityId: json['cityId'],
      address: json['address'],
      city: json['city'],
      zipCode: json['zipCode'],
      streetName: json['streetName'],
      streetNumber: json['streetNumber'],
      description: json['description'],
      price: json['price'].toDouble(),
      facilities: json['facilities'],
      status: json['status'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      dateAdded: json['dateAdded'] != null ? DateTime.parse(json['dateAdded']) : null,
      name: json['name'],
      averageRating: json['averageRating']?.toDouble(),
      images: (json['images'] as List).map((i) => ImageResponse.fromJson(i)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'propertyId': propertyId,
      'ownerId': ownerId,
      'cityId': cityId,
      'address': address,
      'city': city,
      'zipCode': zipCode,
      'streetName': streetName,
      'streetNumber': streetNumber,
      'description': description,
      'price': price,
      'facilities': facilities,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'dateAdded': dateAdded?.toIso8601String(),
      'name': name,
      'averageRating': averageRating,
    };
  }
}
