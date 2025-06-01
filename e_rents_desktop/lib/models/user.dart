import './address_detail.dart';
import 'package:e_rents_desktop/models/image_info.dart' as erents;

enum UserType { admin, landlord, tenant }

class User {
  final int id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String? phone;
  final UserType role;
  final erents.ImageInfo? profileImage;
  final DateTime? dateOfBirth;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? resetToken;
  final DateTime? resetTokenExpiration;

  final int? addressDetailId;
  final AddressDetail? addressDetail;

  final bool isPaypalLinked;
  final String? paypalUserIdentifier;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.role,
    this.profileImage,
    this.dateOfBirth,
    required this.createdAt,
    required this.updatedAt,
    this.resetToken,
    this.resetTokenExpiration,
    this.isPaypalLinked = false,
    this.paypalUserIdentifier,
    this.addressDetailId,
    this.addressDetail,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['userId'] as int? ?? json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phone: json['phoneNumber'] as String? ?? json['phone'] as String?,
      role: _parseUserType(json['role']),
      profileImage:
          json['profileImage'] != null
              ? erents.ImageInfo.fromJson(
                json['profileImage'] as Map<String, dynamic>,
              )
              : null,
      dateOfBirth:
          json['dateOfBirth'] != null
              ? DateTime.tryParse(json['dateOfBirth'] as String)
              : null,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      resetToken: json['resetToken'] as String?,
      resetTokenExpiration:
          json['resetTokenExpiration'] != null
              ? DateTime.tryParse(json['resetTokenExpiration'] as String)
              : null,
      isPaypalLinked: json['isPaypalLinked'] as bool? ?? false,
      paypalUserIdentifier: json['paypalUserIdentifier'] as String?,
      addressDetailId: json['addressDetailId'] as int?,
      addressDetail:
          json['addressDetail'] != null
              ? AddressDetail.fromJson(
                json['addressDetail'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  static UserType _parseUserType(dynamic role) {
    if (role == null) return UserType.tenant;

    String roleStr = role.toString().toLowerCase();
    switch (roleStr) {
      case 'admin':
        return UserType.admin;
      case 'landlord':
        return UserType.landlord;
      case 'tenant':
        return UserType.tenant;
      default:
        return UserType.tenant;
    }
  }

  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phone,
      'role': role.toString().split('.').last,
      'profileImage': profileImage?.toJson(),
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'resetToken': resetToken,
      'resetTokenExpiration': resetTokenExpiration?.toIso8601String(),
      'isPaypalLinked': isPaypalLinked,
      'paypalUserIdentifier': paypalUserIdentifier,
      'addressDetail': addressDetail?.toJson(),
    };
  }

  String get fullName => '$firstName $lastName';

  User copyWith({
    int? id,
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    String? phone,
    UserType? role,
    erents.ImageInfo? profileImage,
    DateTime? dateOfBirth,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? resetToken,
    DateTime? resetTokenExpiration,
    bool? isPaypalLinked,
    String? paypalUserIdentifier,
    int? addressDetailId,
    AddressDetail? addressDetail,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resetToken: resetToken ?? this.resetToken,
      resetTokenExpiration: resetTokenExpiration ?? this.resetTokenExpiration,
      isPaypalLinked: isPaypalLinked ?? this.isPaypalLinked,
      paypalUserIdentifier: paypalUserIdentifier ?? this.paypalUserIdentifier,
      addressDetailId: addressDetailId ?? this.addressDetailId,
      addressDetail: addressDetail ?? this.addressDetail,
    );
  }
}
