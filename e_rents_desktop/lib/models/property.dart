import 'package:e_rents_desktop/models/address.dart';

/// Property entity model that aligns with the backend API
class Property {
  final int propertyId;
  final int ownerId;
  final String? description;
  final double price;
  final String currency;
  final String? facilities;
  final String status; // Using string to match backend enum
  final DateTime? dateAdded;
  final String name;
  final double? averageRating;
  final List<int> imageIds;
  final List<int> amenityIds;
  final Address? address;
  final int? propertyTypeId;
  final int? rentingTypeId;
  final int? bedrooms;
  final int? bathrooms;
  final double? area;
  final int? minimumStayDays;
  final bool requiresApproval;
  final int? coverImageId;

  Property({
    required this.propertyId,
    required this.ownerId,
    this.description,
    required this.price,
    this.currency = "BAM",
    this.facilities,
    required this.status,
    this.dateAdded,
    required this.name,
    this.averageRating,
    required this.imageIds,
    required this.amenityIds,
    this.address,
    this.propertyTypeId,
    this.rentingTypeId,
    this.bedrooms,
    this.bathrooms,
    this.area,
    this.minimumStayDays,
    this.requiresApproval = false,
    this.coverImageId,
  });

  /// Factory constructor from JSON
  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      propertyId: json['propertyId'] as int? ?? json['id'] as int? ?? 0,
      ownerId: json['ownerId'] as int? ?? 0,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? "BAM",
      facilities: json['facilities'] as String?,
      status: json['status'] as String? ?? 'Available',
      dateAdded: json['dateAdded'] != null ? DateTime.parse(json['dateAdded'] as String) : null,
      name: json['name'] as String? ?? '',
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      imageIds: _parseIds(json['imageIds']),
      amenityIds: _parseIds(json['amenityIds']),
      address: json['address'] != null ? Address.fromJson(json['address'] as Map<String, dynamic>) : null,
      propertyTypeId: json['propertyTypeId'] as int?,
      rentingTypeId: json['rentingTypeId'] as int?,
      bedrooms: json['bedrooms'] as int?,
      bathrooms: json['bathrooms'] as int?,
      area: (json['area'] as num?)?.toDouble(),
      minimumStayDays: json['minimumStayDays'] as int?,
      requiresApproval: json['requiresApproval'] as bool? ?? false,
      coverImageId: json['coverImageId'] as int?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'propertyId': propertyId,
      'ownerId': ownerId,
      'description': description,
      'price': price,
      'currency': currency,
      'facilities': facilities,
      'status': status,
      'dateAdded': dateAdded?.toIso8601String(),
      'name': name,
      'averageRating': averageRating,
      'imageIds': imageIds,
      'amenityIds': amenityIds,
      'address': address?.toJson(),
      'propertyTypeId': propertyTypeId,
      'rentingTypeId': rentingTypeId,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'minimumStayDays': minimumStayDays,
      'requiresApproval': requiresApproval,
      'coverImageId': coverImageId,
    };
  }

  /// Create copy with updated fields
  Property copyWith({
    int? propertyId,
    int? ownerId,
    String? description,
    double? price,
    String? currency,
    String? facilities,
    String? status,
    DateTime? dateAdded,
    String? name,
    double? averageRating,
    List<int>? imageIds,
    List<int>? amenityIds,
    Address? address,
    int? propertyTypeId,
    int? rentingTypeId,
    int? bedrooms,
    int? bathrooms,
    double? area,
    int? minimumStayDays,
    bool? requiresApproval,
    int? coverImageId,
  }) {
    return Property(
      propertyId: propertyId ?? this.propertyId,
      ownerId: ownerId ?? this.ownerId,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      facilities: facilities ?? this.facilities,
      status: status ?? this.status,
      dateAdded: dateAdded ?? this.dateAdded,
      name: name ?? this.name,
      averageRating: averageRating ?? this.averageRating,
      imageIds: imageIds ?? this.imageIds,
      amenityIds: amenityIds ?? this.amenityIds,
      address: address ?? this.address,
      propertyTypeId: propertyTypeId ?? this.propertyTypeId,
      rentingTypeId: rentingTypeId ?? this.rentingTypeId,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      area: area ?? this.area,
      minimumStayDays: minimumStayDays ?? this.minimumStayDays,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      coverImageId: coverImageId ?? this.coverImageId,
    );
  }

  static List<int> _parseIds(dynamic idsValue) {
    if (idsValue == null) return [];
    
    try {
      if (idsValue is List) {
        return idsValue
            .map((id) => id is int ? id : int.tryParse(id.toString()) ?? 0)
            .where((id) => id > 0)
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Property &&
          propertyId == other.propertyId;

  @override
  int get hashCode => propertyId.hashCode;

  @override
  String toString() {
    return 'Property(propertyId: $propertyId, name: $name, price: $price, status: $status)';
  }
}
