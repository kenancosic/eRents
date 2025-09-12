import 'address.dart';
import '../enums/property_enums.dart';

/// Lightweight model for property list cards
class PropertyCardModel {
  // Minimal data required by the card UI
  final int propertyId;
  final String name;
  final double price;
  final String currency;
  final double? averageRating;
  final int? coverImageId;
  final Address? address; // streetLine1 + city are used
  final PropertyRentalType rentalType;

  PropertyCardModel({
    required this.propertyId,
    required this.name,
    required this.price,
    this.currency = 'USD',
    this.averageRating,
    this.coverImageId,
    this.address,
    this.rentalType = PropertyRentalType.monthly,
  });

  factory PropertyCardModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    int? parseIntOrNull(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }
    double? parseDouble(dynamic v) => v == null
        ? null
        : (v is num
            ? v.toDouble()
            : double.tryParse(v.toString()));


    List<int> parseIntList(dynamic value) {
      if (value is List) {
        return value
            .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
            .where((e) => e > 0)
            .toList();
      }
      return [];
    }

    PropertyRentalType parseRentalType(dynamic v) {
      if (v is num) {
        switch (v.toInt()) {
          case 1:
            return PropertyRentalType.daily;
          case 2:
            return PropertyRentalType.monthly;
        }
      }
      final s = v?.toString().toLowerCase();
      if (s == 'daily') return PropertyRentalType.daily;
      if (s == 'monthly') return PropertyRentalType.monthly;
      return PropertyRentalType.monthly;
    }

    // Support both camelCase and PascalCase
    final id = json['propertyId'] ?? json['PropertyId'] ?? json['id'];
    return PropertyCardModel(
      propertyId: parseInt(id),
      name: (json['name'] ?? json['Name'] ?? json['PropertyName'] ?? '').toString(),
      price: parseDouble(json['price'] ?? json['Price']) ?? 0.0,
      currency: (json['currency'] ?? json['Currency'] ?? 'USD').toString(),
      averageRating: parseDouble(json['averageRating'] ?? json['AverageRating'] ?? json['PredictedRating']),
      coverImageId: parseIntOrNull(json['coverImageId'] ?? json['CoverImageId']),
      address: (json['address'] ?? json['Address']) is Map<String, dynamic>
          ? Address.fromJson((json['address'] ?? json['Address']) as Map<String, dynamic>)
          : null,
      rentalType: parseRentalType(json['rentalType'] ?? json['RentingType']),
    );
  }

}
