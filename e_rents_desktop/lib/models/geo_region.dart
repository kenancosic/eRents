class GeoRegion {
  final int? geoRegionId;
  final String city;
  final String? state;
  final String country;
  final String? postalCode;

  GeoRegion({
    this.geoRegionId,
    required this.city,
    this.state,
    required this.country,
    this.postalCode,
  });

  factory GeoRegion.fromJson(Map<String, dynamic> json) {
    return GeoRegion(
      geoRegionId: json['geoRegionId'] as int?,
      city: json['city'] as String? ?? '',
      state: json['state'] as String?,
      country: json['country'] as String? ?? '',
      postalCode: json['postalCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'geoRegionId': geoRegionId,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
    };
  }
}
