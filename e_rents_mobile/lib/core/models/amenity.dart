class Amenity {
  final int amenityId;
  final String amenityName;

  Amenity({required this.amenityId, required this.amenityName});

  factory Amenity.fromJson(Map<String, dynamic> json) {
    // Handle both current API format and backend DTO format
    final amenityId = json['amenityId'] ?? json['AmenityId'] ?? 0;
    final amenityName = json['amenityName'] ?? json['AmenityName'] ?? '';
    
    return Amenity(
      amenityId: amenityId,
      amenityName: amenityName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amenityId': amenityId,
      'amenityName': amenityName,
    };
  }
  
  /// Convert to DTO format for API requests that expect backend DTO structure
  Map<String, dynamic> toDtoJson() {
    return {
      'AmenityId': amenityId,
      'AmenityName': amenityName,
    };
  }
}
