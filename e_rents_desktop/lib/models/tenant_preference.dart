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

  // Fields from other entities - use "EntityName + FieldName" pattern
  final String? userFirstName; // User's first name
  final String? userLastName; // User's last name
  final String? userEmail; // User's email
  final String? userPhoneNumber; // User's phone number
  final String? userCity; // User's city from address
  final String? profileImageUrl; // Profile image URL

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
    this.userFirstName,
    this.userLastName,
    this.userEmail,
    this.userPhoneNumber,
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
      // Fields from other entities - use "EntityName + FieldName" pattern
      userFirstName: json['userFirstName'] as String?,
      userLastName: json['userLastName'] as String?,
      userEmail: json['userEmail'] as String?,
      userPhoneNumber: json['userPhoneNumber'] as String?,
      userCity: json['userCity'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
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
      'matchScore': matchScore,
      'matchReasons': matchReasons,
    };
  }

  // Computed properties for UI convenience (for backward compatibility)
  String? get userFullName =>
      !((userFirstName?.isEmpty ?? true) && (userLastName?.isEmpty ?? true))
          ? '${userFirstName ?? ''} ${userLastName ?? ''}'.trim()
          : null;

  String? get userPhone => userPhoneNumber;
}
