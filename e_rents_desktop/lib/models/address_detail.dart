import './geo_region.dart';

class AddressDetail {
  final int addressDetailId;
  final int geoRegionId;
  final String streetLine1;
  final String? streetLine2;
  final double? latitude;
  final double? longitude;
  final GeoRegion? geoRegion; // Nested GeoRegion object

  AddressDetail({
    required this.addressDetailId,
    required this.geoRegionId,
    required this.streetLine1,
    this.streetLine2,
    this.latitude,
    this.longitude,
    this.geoRegion,
  });

  factory AddressDetail.fromJson(Map<String, dynamic> json) {
    return AddressDetail(
      addressDetailId: json['addressDetailId'] as int,
      geoRegionId: json['geoRegionId'] as int,
      streetLine1: json['streetLine1'] as String,
      streetLine2: json['streetLine2'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      geoRegion:
          json['geoRegion'] != null
              ? GeoRegion.fromJson(json['geoRegion'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addressDetailId': addressDetailId,
      'geoRegionId': geoRegionId,
      'streetLine1': streetLine1,
      'streetLine2': streetLine2,
      'latitude': latitude,
      'longitude': longitude,
      'geoRegion': geoRegion?.toJson(),
    };
  }
}
