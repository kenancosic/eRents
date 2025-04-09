import 'package:flutter/material.dart';

class TenantPreference {
  final String id;
  final String userId;
  final DateTime searchStartDate;
  final DateTime? searchEndDate;
  final double? minPrice;
  final double? maxPrice;
  final String city;
  final List<String> amenities;
  final String description;
  final bool isActive;

  TenantPreference({
    required this.id,
    required this.userId,
    required this.searchStartDate,
    this.searchEndDate,
    this.minPrice,
    this.maxPrice,
    required this.city,
    required this.amenities,
    required this.description,
    this.isActive = true,
  });

  factory TenantPreference.fromJson(Map<String, dynamic> json) {
    return TenantPreference(
      id: json['id'],
      userId: json['userId'],
      searchStartDate: DateTime.parse(json['searchStartDate']),
      searchEndDate:
          json['searchEndDate'] != null
              ? DateTime.parse(json['searchEndDate'])
              : null,
      minPrice: json['minPrice'],
      maxPrice: json['maxPrice'],
      city: json['city'],
      amenities: List<String>.from(json['amenities']),
      description: json['description'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'searchStartDate': searchStartDate.toIso8601String(),
      'searchEndDate': searchEndDate?.toIso8601String(),
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'city': city,
      'amenities': amenities,
      'description': description,
      'isActive': isActive,
    };
  }
}
