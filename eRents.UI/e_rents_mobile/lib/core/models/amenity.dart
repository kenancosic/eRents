class Amenity {
  final int amenityId;
  final String amenityName;

  Amenity({required this.amenityId, required this.amenityName});

  factory Amenity.fromJson(Map<String, dynamic> json) {
    return Amenity(
      amenityId: json['amenityId'],
      amenityName: json['amenityName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amenityId': amenityId,
      'amenityName': amenityName,
    };
  }
}
