import 'address.dart';
import '../enums/property_enums.dart';

/// Comprehensive model for property detail screens
class PropertyDetail {
  final int propertyId;
  final int ownerId;
  final String name;
  final String? description;
  final double price;
  final String currency;
  final double? averageRating;
  final int? reviewCount;
  final List<int> imageIds;
  final int? coverImageId;
  final List<int> amenityIds;
  final Address? address;
  final PropertyRentalType rentalType;
  final PropertyType? propertyType;
  final PropertyStatus status;

  // Specs
  final int rooms;
  final double? area;
  final double? dailyRate;
  final int? minimumStayDays;
  final bool? requiresApproval;

  // Availability
  final DateTime? unavailableFrom;
  final DateTime? unavailableTo;

  // Optional: future-ready fields
  // final List<Review> reviews; // if/when added

  PropertyDetail({
    required this.propertyId,
    required this.ownerId,
    required this.name,
    this.description,
    required this.price,
    this.currency = 'USD',
    this.averageRating,
    this.reviewCount,
    required this.imageIds,
    this.coverImageId,
    required this.amenityIds,
    this.address,
    this.rentalType = PropertyRentalType.monthly,
    this.propertyType,
    this.status = PropertyStatus.available,
    required this.rooms,
    this.area,
    this.dailyRate,
    this.minimumStayDays,
    this.requiresApproval,
    this.unavailableFrom,
    this.unavailableTo,
  });

  factory PropertyDetail.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    double? parseDouble(dynamic v) => v == null
        ? null
        : (v is num ? v.toDouble() : double.tryParse(v.toString()));

    T? parseEnum<T>(List<T> values, dynamic v) {
      if (v == null) return null;
      final s = v.toString().toLowerCase();
      for (final val in values) {
        final name = val.toString().split('.').last.toLowerCase();
        if (name == s) return val;
      }
      return null;
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v is String ? v : v.toString());
      } catch (_) {
        return null;
      }
    }

    List<int> parseIntList(dynamic value) {
      if (value is List) {
        return value
            .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
            .where((e) => e > 0)
            .toList();
      }
      return [];
    }

    PropertyRentalType parseRentalTypeVal(dynamic v) {
      if (v is num) {
        switch (v.toInt()) {
          case 1:
            return PropertyRentalType.daily;
          case 2:
            return PropertyRentalType.monthly;
        }
      }
      final parsed = parseEnum<PropertyRentalType>(PropertyRentalType.values, v);
      return parsed ?? PropertyRentalType.monthly;
    }

    PropertyType? parsePropertyTypeVal(dynamic v) {
      if (v is num) {
        switch (v.toInt()) {
          case 1:
            return PropertyType.apartment;
          case 2:
            return PropertyType.house;
          case 3:
            return PropertyType.studio;
          case 4:
            return PropertyType.villa;
          case 5:
            return PropertyType.room;
        }
      }
      return parseEnum<PropertyType>(PropertyType.values, v);
    }

    PropertyStatus parseStatusVal(dynamic v) {
      if (v is num) {
        switch (v.toInt()) {
          case 1:
            return PropertyStatus.available;
          case 2:
            return PropertyStatus.rented; // Occupied -> rented
          case 3:
            return PropertyStatus.maintenance; // UnderMaintenance -> maintenance
          case 4:
            return PropertyStatus.unavailable;
        }
      }
      final s = v?.toString().toLowerCase();
      if (s == 'occupied') return PropertyStatus.rented;
      if (s == 'undermaintenance' || s == 'under_maintenance' || s == 'under maintenance') return PropertyStatus.maintenance;
      return parseEnum<PropertyStatus>(PropertyStatus.values, v) ?? PropertyStatus.available;
    }

    final id = json['propertyId'] ?? json['PropertyId'] ?? json['id'];
    final owner = json['ownerId'] ?? json['OwnerId'];

    return PropertyDetail(
      propertyId: parseInt(id),
      ownerId: parseInt(owner),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      description: (json['description'] ?? json['Description'])?.toString(),
      price: parseDouble(json['price'] ?? json['Price']) ?? 0.0,
      currency: (json['currency'] ?? json['Currency'] ?? 'USD').toString(),
      averageRating: parseDouble(json['averageRating'] ?? json['AverageRating']),
      reviewCount: json['reviewCount'] is int
          ? json['reviewCount']
          : int.tryParse(json['reviewCount']?.toString() ?? ''),
      imageIds: parseIntList(json['imageIds'] ?? json['ImageIds']),
      coverImageId: json['coverImageId'] is int
          ? json['coverImageId']
          : int.tryParse(json['coverImageId']?.toString() ?? ''),
      amenityIds: parseIntList(json['amenityIds'] ?? json['AmenityIds']),
      address: (json['address'] ?? json['Address']) is Map<String, dynamic>
          ? Address.fromJson((json['address'] ?? json['Address']) as Map<String, dynamic>)
          : null,
      rentalType: parseRentalTypeVal(json['rentalType'] ?? json['RentingType']),
      propertyType: parsePropertyTypeVal(json['propertyType'] ?? json['PropertyType']),
      status: parseStatusVal(json['status'] ?? json['Status']),
      rooms: parseInt(json['rooms'] ?? json['Rooms'] ?? '0'),
      area: parseDouble(json['area'] ?? json['Area']),
      dailyRate: parseDouble(json['dailyRate'] ?? json['DailyRate']),
      minimumStayDays: parseInt(json['minimumStayDays'] ?? json['MinimumStayDays'] ?? '0'),
      requiresApproval: (json['requiresApproval'] ?? json['RequiresApproval'])?.toString().toLowerCase() == 'true',
      unavailableFrom: parseDate(json['unavailableFrom'] ?? json['UnavailableFrom']),
      unavailableTo: parseDate(json['unavailableTo'] ?? json['UnavailableTo']),
    );
  }
}
