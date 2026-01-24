import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/models/enums/user_type.dart';

class User {
  final int userId;
  final String email;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final UserType userType;
  final int? profileImageId;
  final DateTime? dateOfBirth;
  final bool? isPublic;

  // Stripe payment fields
  final String? stripeCustomerId;
  final String? stripeAccountId;
  final String? stripeAccountStatus;

  // BaseEntity fields
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? createdBy;
  final int? modifiedBy;

  // Navigation properties - excluded from JSON serialization
  final Address? address;

  const User({
    required this.userId,
    required this.email,
    required this.username,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.userType = UserType.guest,
    this.profileImageId,
    this.dateOfBirth,
    this.isPublic,
    this.stripeCustomerId,
    this.stripeAccountId,
    this.stripeAccountStatus,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.modifiedBy,
    this.address,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      final s = v.toString();
      return s.isEmpty ? null : DateTime.tryParse(s);
    }
    String? _asString(dynamic v) => v == null ? null : v.toString();
    int? _asInt(dynamic v) => (v is num) ? v.toInt() : (v != null ? int.tryParse(v.toString()) : null);
    bool? _asBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      final s = v.toString().toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
      return null;
    }
    final created = _parseDate(json['createdAt']) ?? DateTime.now();
    final updated = _parseDate(json['updatedAt']) ?? created;
    // Backend flattens address fields; compose Address here for convenience
    final addr = (json.containsKey('city') || json.containsKey('streetLine1'))
        ? Address.fromJson(json)
        : null;
    // Be tolerant of different ID key names/casing from backend (e.g., 'Id' in chat contacts)
    final parsedUserId = _asInt(
          json['userId'] ?? json['UserId'] ?? json['id'] ?? json['Id']
        ) ?? 0;
    return User(
      userId: parsedUserId,
      email: _asString(json['email'] ?? json['Email']) ?? '',
      username: _asString(json['username'] ?? json['Username']) ?? '',
      firstName: _asString(json['firstName'] ?? json['FirstName']),
      lastName: _asString(json['lastName'] ?? json['LastName']),
      phoneNumber: _asString(json['phoneNumber']),
      userType: UserType.fromDynamic(json['userType'] ?? json['UserType']),
      profileImageId: _asInt(json['profileImageId'] ?? json['ProfileImageId']),
      dateOfBirth: _parseDate(json['dateOfBirth'] ?? json['DateOfBirth']),
      isPublic: _asBool(json['isPublic'] ?? json['IsPublic']),
      stripeCustomerId: _asString(json['stripeCustomerId']),
      stripeAccountId: _asString(json['stripeAccountId']),
      stripeAccountStatus: _asString(json['stripeAccountStatus']),
      createdAt: created,
      updatedAt: updated,
      createdBy: _asInt(json['createdBy']),
      modifiedBy: _asInt(json['modifiedBy']),
      address: addr,
    );
  }

  Map<String, dynamic> toJson() {
    // Format DateOnly fields as yyyy-MM-dd for .NET DateOnly compatibility
    String? formatDateOnly(DateTime? dt) {
      if (dt == null) return null;
      return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }

    return <String, dynamic>{
      'userId': userId,
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'userType': userType.name,
      'profileImageId': profileImageId,
      'dateOfBirth': formatDateOnly(dateOfBirth),
      'isPublic': isPublic,
      'stripeCustomerId': stripeCustomerId,
      'stripeAccountId': stripeAccountId,
      'stripeAccountStatus': stripeAccountStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'modifiedBy': modifiedBy,
    };
  }

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  // CopyWith method for immutable updates
  User copyWith({
    int? userId,
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    UserType? userType,
    int? profileImageId,
    DateTime? dateOfBirth,
    bool? isPublic,
    String? stripeCustomerId,
    String? stripeAccountId,
    String? stripeAccountStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? createdBy,
    int? modifiedBy,
    Address? address,
  }) {
    return User(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userType: userType ?? this.userType,
      profileImageId: profileImageId ?? this.profileImageId,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      isPublic: isPublic ?? this.isPublic,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      stripeAccountId: stripeAccountId ?? this.stripeAccountId,
      stripeAccountStatus: stripeAccountStatus ?? this.stripeAccountStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      modifiedBy: modifiedBy ?? this.modifiedBy,
      address: address ?? this.address,
    );
  }

  // Legacy compatibility getters
  int get id => userId;
  UserType get role => userType;
  String? get phone => phoneNumber;
}