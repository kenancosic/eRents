import 'package:flutter/foundation.dart';

class TenantPreferenceModel {
  final String? id; // Preference ID, if persisted
  final String userId; // Link to the User
  final String? city;
  final double? minPrice;
  final double? maxPrice;
  final DateTime? moveInStartDate;
  final DateTime? moveInEndDate; // Optional
  final List<String>? amenities;
  final String? description;
  final bool?
      isPublic; // If these preferences are part of a public advertisement

  TenantPreferenceModel({
    this.id,
    required this.userId,
    this.city,
    this.minPrice,
    this.maxPrice,
    this.moveInStartDate,
    this.moveInEndDate,
    this.amenities,
    this.description,
    this.isPublic,
  });

  factory TenantPreferenceModel.fromJson(Map<String, dynamic> json) {
    return TenantPreferenceModel(
      id: json['id'],
      userId: json['userId'],
      city: json['city'],
      minPrice: (json['minPrice'] as num?)?.toDouble(),
      maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      moveInStartDate: json['moveInStartDate'] != null
          ? DateTime.parse(json['moveInStartDate'])
          : null,
      moveInEndDate: json['moveInEndDate'] != null
          ? DateTime.parse(json['moveInEndDate'])
          : null,
      amenities: json['amenities'] != null
          ? List<String>.from(json['amenities'])
          : null,
      description: json['description'],
      isPublic: json['isPublic'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'city': city,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'moveInStartDate': moveInStartDate?.toIso8601String(),
      'moveInEndDate': moveInEndDate?.toIso8601String(),
      'amenities': amenities,
      'description': description,
      'isPublic': isPublic,
    };
  }

  TenantPreferenceModel copyWith({
    String? id,
    String? userId,
    String? city,
    double? minPrice,
    double? maxPrice,
    DateTime? moveInStartDate,
    DateTime? moveInEndDate,
    List<String>? amenities,
    String? description,
    bool? isPublic,
  }) {
    return TenantPreferenceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      city: city ?? this.city,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      moveInStartDate: moveInStartDate ?? this.moveInStartDate,
      moveInEndDate: moveInEndDate ?? this.moveInEndDate,
      amenities: amenities ?? this.amenities,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TenantPreferenceModel &&
        other.id == id &&
        other.userId == userId &&
        other.city == city &&
        other.minPrice == minPrice &&
        other.maxPrice == maxPrice &&
        other.moveInStartDate == moveInStartDate &&
        other.moveInEndDate == moveInEndDate &&
        listEquals(other.amenities, amenities) &&
        other.description == description &&
        other.isPublic == isPublic;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        city.hashCode ^
        minPrice.hashCode ^
        maxPrice.hashCode ^
        moveInStartDate.hashCode ^
        moveInEndDate.hashCode ^
        amenities.hashCode ^
        description.hashCode ^
        isPublic.hashCode;
  }
}
