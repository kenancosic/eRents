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
    );
  }

  String? get name => firstName;
  String? get userType => role;
  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
}
