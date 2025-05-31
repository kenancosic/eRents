class TenantPreference {
  final int id;
  final int userId;
  final DateTime searchStartDate;
  final DateTime? searchEndDate;
  final double? minPrice;
  final double? maxPrice;
  final String city;
  final List<String> amenities;
  final String description;
  final bool isActive;

  // User information from backend TenantPreferenceResponseDto
  final String? userFullName;
  final String? userEmail;
  final String? userPhone;
  final String? userCity;
  final String? profileImageUrl;

  // Match scoring from backend
  final double matchScore;
  final List<String> matchReasons;

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
    this.userFullName,
    this.userEmail,
    this.userPhone,
    this.userCity,
    this.profileImageUrl,
    this.matchScore = 0.0,
    this.matchReasons = const [],
  });

  factory TenantPreference.fromJson(Map<String, dynamic> json) {
    return TenantPreference(
      id: json['id'] as int,
      userId: json['userId'] as int,
      searchStartDate: DateTime.parse(json['searchStartDate']),
      searchEndDate:
          json['searchEndDate'] != null
              ? DateTime.parse(json['searchEndDate'])
              : null,
      minPrice: json['minPrice'],
      maxPrice: json['maxPrice'],
      city: json['city'],
      amenities: List<String>.from(json['amenities'] ?? []),
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? true,
      // User information from backend
      userFullName: json['userFullName'],
      userEmail: json['userEmail'],
      userPhone: json['userPhone'],
      userCity: json['userCity'],
      profileImageUrl: json['profileImageUrl'],
      // Match scoring
      matchScore: (json['matchScore'] ?? 0.0).toDouble(),
      matchReasons: List<String>.from(json['matchReasons'] ?? []),
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
      'userFullName': userFullName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'userCity': userCity,
      'profileImageUrl': profileImageUrl,
      'matchScore': matchScore,
      'matchReasons': matchReasons,
    };
  }
}
