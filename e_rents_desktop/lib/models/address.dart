
class Address {
  final String? streetLine1;
  final String? streetLine2;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final double? latitude;
  final double? longitude;

  const Address({
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
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }
    return Address(
      streetLine1: json['streetLine1'] as String?,
      streetLine2: json['streetLine2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      postalCode: json['postalCode'] as String?,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'streetLine1': streetLine1,
        'streetLine2': streetLine2,
        'city': city,
        'state': state,
        'country': country,
        'postalCode': postalCode,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory Address.empty() {
    return const Address(
      streetLine1: '',
      streetLine2: '',
      city: '',
      state: '',
      country: '',
      postalCode: '',
      latitude: null,
      longitude: null,
    );
  }

  String getFullAddress() {
    final parts = [
      streetLine1,
      streetLine2,
      city,
      state,
      country,
      postalCode,
    ].where((part) => part?.isNotEmpty == true);
    return parts.join(', ');
  }

  String getStreetAddress() {
    final parts = [
      streetLine1,
      streetLine2,
    ].where((part) => part?.isNotEmpty == true);
    return parts.join(', ');
  }

  String getCityStateCountry() {
    final parts = [
      city,
      state,
      country,
    ].where((part) => part?.isNotEmpty == true);
    return parts.join(', ');
  }

  bool get isEmpty => (streetLine1?.isEmpty ?? true) && (city?.isEmpty ?? true);
  bool get isNotEmpty => !isEmpty;

  @override
  String toString() => getFullAddress();
}