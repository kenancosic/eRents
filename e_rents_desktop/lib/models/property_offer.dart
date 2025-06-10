class PropertyOffer {
  final int offerId;
  final int tenantId;
  final int propertyId;
  final int landlordId;
  final DateTime dateOffered;
  final String status; // Pending, Accepted, Rejected, Expired
  final String? message;

  // Fields from other entities - use "EntityName + FieldName" pattern
  final String? propertyName; // Property name
  final double? propertyPrice; // Property price
  final String? userFirstNameTenant; // Tenant's first name
  final String? userLastNameTenant; // Tenant's last name
  final String? userEmailTenant; // Tenant's email
  final String? userFirstNameLandlord; // Landlord's first name
  final String? userLastNameLandlord; // Landlord's last name

  PropertyOffer({
    required this.offerId,
    required this.tenantId,
    required this.propertyId,
    required this.landlordId,
    required this.dateOffered,
    this.status = 'Pending',
    this.message,
    this.propertyName,
    this.propertyPrice,
    this.userFirstNameTenant,
    this.userLastNameTenant,
    this.userEmailTenant,
    this.userFirstNameLandlord,
    this.userLastNameLandlord,
  });

  factory PropertyOffer.fromJson(Map<String, dynamic> json) {
    return PropertyOffer(
      offerId: json['offerId'] as int,
      tenantId: json['tenantId'] as int,
      propertyId: json['propertyId'] as int,
      landlordId: json['landlordId'] as int,
      dateOffered: DateTime.parse(json['dateOffered'] as String),
      status: json['status'] as String? ?? 'Pending',
      message: json['message'] as String?,
      // Fields from other entities - use "EntityName + FieldName" pattern
      propertyName: json['propertyName'] as String?,
      propertyPrice: (json['propertyPrice'] as num?)?.toDouble(),
      userFirstNameTenant: json['userFirstNameTenant'] as String?,
      userLastNameTenant: json['userLastNameTenant'] as String?,
      userEmailTenant: json['userEmailTenant'] as String?,
      userFirstNameLandlord: json['userFirstNameLandlord'] as String?,
      userLastNameLandlord: json['userLastNameLandlord'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offerId': offerId,
      'tenantId': tenantId,
      'propertyId': propertyId,
      'landlordId': landlordId,
      'dateOffered': dateOffered.toIso8601String(),
      'status': status,
      'message': message,
    };
  }

  PropertyOffer copyWith({
    int? offerId,
    int? tenantId,
    int? propertyId,
    int? landlordId,
    DateTime? dateOffered,
    String? status,
    String? message,
    String? propertyName,
    double? propertyPrice,
    String? userFirstNameTenant,
    String? userLastNameTenant,
    String? userEmailTenant,
    String? userFirstNameLandlord,
    String? userLastNameLandlord,
  }) {
    return PropertyOffer(
      offerId: offerId ?? this.offerId,
      tenantId: tenantId ?? this.tenantId,
      propertyId: propertyId ?? this.propertyId,
      landlordId: landlordId ?? this.landlordId,
      dateOffered: dateOffered ?? this.dateOffered,
      status: status ?? this.status,
      message: message ?? this.message,
      propertyName: propertyName ?? this.propertyName,
      propertyPrice: propertyPrice ?? this.propertyPrice,
      userFirstNameTenant: userFirstNameTenant ?? this.userFirstNameTenant,
      userLastNameTenant: userLastNameTenant ?? this.userLastNameTenant,
      userEmailTenant: userEmailTenant ?? this.userEmailTenant,
      userFirstNameLandlord:
          userFirstNameLandlord ?? this.userFirstNameLandlord,
      userLastNameLandlord: userLastNameLandlord ?? this.userLastNameLandlord,
    );
  }

  // Computed properties for UI convenience (for backward compatibility)
  String? get propertyTitle => propertyName; // Alias for backward compatibility

  String? get tenantFullName =>
      !((userFirstNameTenant?.isEmpty ?? true) &&
              (userLastNameTenant?.isEmpty ?? true))
          ? '${userFirstNameTenant ?? ''} ${userLastNameTenant ?? ''}'.trim()
          : null;

  String? get tenantEmail =>
      userEmailTenant; // Alias for backward compatibility

  String? get landlordFullName =>
      !((userFirstNameLandlord?.isEmpty ?? true) &&
              (userLastNameLandlord?.isEmpty ?? true))
          ? '${userFirstNameLandlord ?? ''} ${userLastNameLandlord ?? ''}'
              .trim()
          : null;

  // Helper methods for status checking
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isAccepted => status.toLowerCase() == 'accepted';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isExpired => status.toLowerCase() == 'expired';
}

/// Property offer request model for creating new offers
class PropertyOfferRequest {
  final int receiverId;
  final int propertyId;
  final String? message;

  const PropertyOfferRequest({
    required this.receiverId,
    required this.propertyId,
    this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'receiverId': receiverId,
      'propertyId': propertyId,
      'message': message,
    };
  }
}
