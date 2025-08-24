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

  // PayPal-related properties
  final bool isPaypalLinked;
  final String? paypalUserIdentifier;

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
    this.isPaypalLinked = false,
    this.paypalUserIdentifier,
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
    return User(
      userId: (json['userId'] as num).toInt(),
      email: _asString(json['email']) ?? '',
      username: _asString(json['username']) ?? '',
      firstName: _asString(json['firstName']),
      lastName: _asString(json['lastName']),
      phoneNumber: _asString(json['phoneNumber']),
      userType: UserType.fromDynamic(json['userType']),
      profileImageId: _asInt(json['profileImageId']),
      dateOfBirth: _parseDate(json['dateOfBirth']),
      isPublic: _asBool(json['isPublic']),
      isPaypalLinked: _asBool(json['isPaypalLinked']) ?? false,
      paypalUserIdentifier: _asString(json['paypalUserIdentifier']),
      createdAt: created,
      updatedAt: updated,
      createdBy: _asInt(json['createdBy']),
      modifiedBy: _asInt(json['modifiedBy']),
      address: addr,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'userId': userId,
        'email': email,
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'userType': userType.name,
        'profileImageId': profileImageId,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'isPublic': isPublic,
        'isPaypalLinked': isPaypalLinked,
        'paypalUserIdentifier': paypalUserIdentifier,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'createdBy': createdBy,
        'modifiedBy': modifiedBy,
      };

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
    bool? isPaypalLinked,
    String? paypalUserIdentifier,
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
      isPaypalLinked: isPaypalLinked ?? this.isPaypalLinked,
      paypalUserIdentifier: paypalUserIdentifier ?? this.paypalUserIdentifier,
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