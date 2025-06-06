import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import './address.dart';

enum PropertyStatus { available, rented, maintenance, unavailable }

enum PropertyType { apartment, house, condo, townhouse, studio }

class Property {
  final int id;
  final int ownerId;
  final String title;
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
  final double? dailyRate;
  final int? minimumStayDays;
  final DateTime dateAdded;
  final Address? address;

  Property({
    required this.id,
    required this.ownerId,
    required this.title,
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
    this.dailyRate,
    this.minimumStayDays,
    required this.dateAdded,
    this.address,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    print('Property.fromJson: Parsing property data: ${json.keys.toList()}');

    return Property(
      // Handle both propertyId and id field names from backend
      id: json['propertyId'] as int? ?? json['id'] as int? ?? 0,
      ownerId: json['ownerId'] as int? ?? 0,
      // Handle both name and title field names
      title: json['name'] as String? ?? json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: _parsePropertyType(json['type'] ?? json['propertyType']),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      rentingType: _parseRentingType(
        json['rentingType'] ?? json['rentingTypeId'],
      ),
      status: _parsePropertyStatus(json['status'] ?? json['statusId']),
      imageIds: _parseImageIds(json['imageIds']),
      bedrooms: json['bedrooms'] as int? ?? 0,
      bathrooms: json['bathrooms'] as int? ?? 0,
      area: (json['area'] as num?)?.toDouble() ?? 0.0,
      maintenanceIssues: _parseMaintenanceIssues(json['maintenanceIssues']),
      amenityIds: _parseAmenityIds(json['amenityIds']),
      currency: json['currency'] as String? ?? "BAM",
      dailyRate: (json['dailyRate'] as num?)?.toDouble(),
      minimumStayDays: json['minimumStayDays'] as int?,
      dateAdded:
          json['dateAdded'] != null
              ? DateTime.parse(json['dateAdded'] as String)
              : DateTime.now(),
      address:
          json['addressDetail'] != null
              ? Address.fromJson(json['addressDetail'] as Map<String, dynamic>)
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
      'propertyId': id,
      'ownerId': ownerId,
      'name': title,
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
      'dailyRate': dailyRate,
      'minimumStayDays': minimumStayDays,
      'dateAdded': dateAdded.toIso8601String(),
      'addressDetail': address?.toAddressDetailJson(),
      'amenityIds': amenityIds,
    };
  }

  Property copyWith({
    int? id,
    int? ownerId,
    String? title,
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
    double? dailyRate,
    int? minimumStayDays,
    DateTime? dateAdded,
    Address? address,
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
      imageIds: imageIds ?? this.imageIds,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      area: area ?? this.area,
      maintenanceIssues: maintenanceIssues ?? this.maintenanceIssues,
      amenityIds: amenityIds ?? this.amenityIds,
      currency: currency ?? this.currency,
      dailyRate: dailyRate ?? this.dailyRate,
      minimumStayDays: minimumStayDays ?? this.minimumStayDays,
      dateAdded: dateAdded ?? this.dateAdded,
      address: address ?? this.address,
    );
  }

  factory Property.empty() => Property(
    id: 0,
    ownerId: 0,
    title: 'N/A',
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
}
