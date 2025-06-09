import './address.dart';

class User {
  final int? userId;
  final String username;
  final String email;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? role;
  final String? firstName;
  final String? lastName;
  final int? profileImageId;
  final String? password;
  final String? token;
  final bool? isPublic;
  final Address? address;

  // ✅ NEW CRITICAL FIELDS for backend alignment
  final int? userTypeId; // Backend expects userTypeId
  final DateTime? createdAt; // Backend tracks creation time
  final DateTime? updatedAt; // Backend tracks updates
  final bool? isPaypalLinked; // PayPal integration status
  final String? paypalUserIdentifier; // PayPal user reference

  User({
    this.userId,
    required this.username,
    required this.email,
    this.phoneNumber,
    this.dateOfBirth,
    this.role,
    this.firstName,
    this.lastName,
    this.profileImageId,
    this.password,
    this.token,
    this.isPublic,
    this.address,
    // New fields
    this.userTypeId,
    this.createdAt,
    this.updatedAt,
    this.isPaypalLinked,
    this.paypalUserIdentifier,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] as int?,
      username: json['username'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : null,
      role: json['role'] ?? json['userType'],
      firstName: json['firstName'] ?? json['name'],
      lastName: json['lastName'] as String?,
      profileImageId: json['profileImageId'] as int?,
      password: json['password'] as String?,
      token: json['resetToken'] as String?,
      isPublic: json['isPublic'] as bool?,
      address: json['addressDetail'] != null
          ? Address.fromJson(json['addressDetail'] as Map<String, dynamic>)
          : null,
      // New fields parsing
      userTypeId: json['userTypeId'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      isPaypalLinked: json['isPaypalLinked'] as bool?,
      paypalUserIdentifier: json['paypalUserIdentifier'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'profileImageId': profileImageId,
      'password': password,
      'resetToken': token,
      'isPublic': isPublic,
      'addressDetail': address?.toAddressDetailJson(),
      // New fields
      'userTypeId': userTypeId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isPaypalLinked': isPaypalLinked,
      'paypalUserIdentifier': paypalUserIdentifier,
    };
  }

  User copyWith({
    int? userId,
    String? username,
    String? email,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? role,
    String? firstName,
    String? lastName,
    int? profileImageId,
    String? password,
    String? token,
    bool? isPublic,
    Address? address,
    int? userTypeId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPaypalLinked,
    String? paypalUserIdentifier,
  }) {
    return User(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImageId: profileImageId ?? this.profileImageId,
      password: password ?? this.password,
      token: token ?? this.token,
      isPublic: isPublic ?? this.isPublic,
      address: address ?? this.address,
      userTypeId: userTypeId ?? this.userTypeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPaypalLinked: isPaypalLinked ?? this.isPaypalLinked,
      paypalUserIdentifier: paypalUserIdentifier ?? this.paypalUserIdentifier,
    );
  }

  String? get name => firstName;
  String? get userType => role;
  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
}
