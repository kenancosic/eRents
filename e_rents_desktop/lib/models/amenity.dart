import 'package:e_rents_desktop/models/property.dart';

class Amenity {
  final int amenityId;
  final String amenityName;

  // BaseEntity fields
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? createdBy;
  final int? modifiedBy;

  // Navigation properties - excluded from JSON serialization
  final List<Property>? properties;

  const Amenity({
    required this.amenityId,
    required this.amenityName,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.modifiedBy,
    this.properties,
  });

  factory Amenity.fromJson(Map<String, dynamic> json) {
    DateTime _dt(dynamic v) => v is String ? DateTime.parse(v) : v as DateTime;
    return Amenity(
      amenityId: (json['amenityId'] as num).toInt(),
      amenityName: json['amenityName'] as String,
      createdAt: _dt(json['createdAt']),
      updatedAt: _dt(json['updatedAt']),
      createdBy: (json['createdBy'] as num?)?.toInt(),
      modifiedBy: (json['modifiedBy'] as num?)?.toInt(),
      properties: null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'amenityId': amenityId,
        'amenityName': amenityName,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'createdBy': createdBy,
        'modifiedBy': modifiedBy,
        // properties intentionally omitted
      };
}