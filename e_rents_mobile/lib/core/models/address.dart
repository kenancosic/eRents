class Address {
  final String? streetLine1;
  final String? streetLine2;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final double? latitude;
  final double? longitude;

  Address({
    this.streetLine1,
    this.streetLine2,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.latitude,
    this.longitude,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    // Handle both new Address format and legacy AddressDetail format for backward compatibility
    if (json.containsKey('geoRegion')) {
      // Legacy AddressDetail format - transform to new structure
      final geoRegion = json['geoRegion'] as Map<String, dynamic>?;
      return Address(
        streetLine1: json['streetLine1'] as String?,
        streetLine2: json['streetLine2'] as String?,
        city: geoRegion?['city'] as String?,
        state: geoRegion?['state'] as String?,
        country: geoRegion?['country'] as String?,
        postalCode: geoRegion?['postalCode'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
    } else {
      // New flat Address format
      return Address(
        streetLine1: json['streetLine1'] as String?,
        streetLine2: json['streetLine2'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        country: json['country'] as String?,
        postalCode: json['postalCode'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'streetLine1': streetLine1,
      'streetLine2': streetLine2,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Transform to backend-compatible AddressDetail format for API calls
  Map<String, dynamic> toAddressDetailJson() {
    return {
      'streetLine1': streetLine1,
      'streetLine2': streetLine2,
      'latitude': latitude,
      'longitude': longitude,
      'geoRegion': {
        'city': city,
        'state': state,
        'country': country,
        'postalCode': postalCode,
      },
    };
  }

  String getFullAddress() {
    final parts = [streetLine1, streetLine2, city, state, country, postalCode]
        .where((part) => part?.isNotEmpty == true);
    return parts.join(', ');
  }

  String getStreetAddress() {
    final parts =
        [streetLine1, streetLine2].where((part) => part?.isNotEmpty == true);
    return parts.join(', ');
  }

  String getCityStateCountry() {
    final parts =
        [city, state, country].where((part) => part?.isNotEmpty == true);
    return parts.join(', ');
  }

  String getDisplayAddress() {
    // For mobile UI - shorter display format
    final streetPart = getStreetAddress();
    final cityPart = city ?? '';

    if (streetPart.isNotEmpty && cityPart.isNotEmpty) {
      return '$streetPart, $cityPart';
    } else if (streetPart.isNotEmpty) {
      return streetPart;
    } else if (cityPart.isNotEmpty) {
      return cityPart;
    }
    return 'No address';
  }

  bool get isEmpty => (streetLine1?.isEmpty ?? true) && (city?.isEmpty ?? true);

  bool get isNotEmpty => !isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address &&
        other.streetLine1 == streetLine1 &&
        other.streetLine2 == streetLine2 &&
        other.city == city &&
        other.state == state &&
        other.country == country &&
        other.postalCode == postalCode &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode {
    return Object.hash(
      streetLine1,
      streetLine2,
      city,
      state,
      country,
      postalCode,
      latitude,
      longitude,
    );
  }

  @override
  String toString() {
    return 'Address(${getFullAddress()})';
  }

  Address copyWith({
    String? streetLine1,
    String? streetLine2,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    double? latitude,
    double? longitude,
  }) {
    return Address(
      streetLine1: streetLine1 ?? this.streetLine1,
      streetLine2: streetLine2 ?? this.streetLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
