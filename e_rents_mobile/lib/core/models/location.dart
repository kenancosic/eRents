class Location {
  final int? locationId;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final String? address; // Optional detailed address

  Location({
    this.locationId,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.address,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      locationId: json['locationId'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      postalCode: json['postalCode'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locationId': locationId,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }
}
