class Location {
  final double latitude;
  final double longitude;
  final String? address; // Optional detailed address

  Location({required this.latitude, required this.longitude, this.address});

  // Add methods for serialization/deserialization if necessary
}
