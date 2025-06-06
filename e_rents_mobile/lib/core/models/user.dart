import './address_detail.dart';

class User {
  final int? userId;
  final String username;
  final String email;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? userType;
  final String? name;
  final String? lastName;
  final String? password;
  final String? token;
  final bool? isPublic;
  final int? addressDetailId;
  final AddressDetail? addressDetail;

  User({
    this.userId,
    required this.username,
    required this.email,
    this.phoneNumber,
    this.dateOfBirth,
    this.userType,
    this.name,
    this.lastName,
    this.password,
    this.token,
    this.isPublic,
    this.addressDetailId,
    this.addressDetail,
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
      userType: json['userType'] as String?,
      name: json['name'] as String?,
      lastName: json['lastName'] as String?,
      password: json['password'] as String?,
      token: json['resetToken'] as String?,
      isPublic: json['isPublic'] as bool?,
      addressDetailId: json['addressDetailId'] as int?,
      addressDetail: json['addressDetail'] != null
          ? AddressDetail.fromJson(
              json['addressDetail'] as Map<String, dynamic>)
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
      'userType': userType,
      'name': name,
      'lastName': lastName,
      'password': password,
      'resetToken': token,
      'isPublic': isPublic,
      'addressDetailId': addressDetailId,
    };
  }

  User copyWith({
    int? userId,
    String? username,
    String? email,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? userType,
    String? name,
    String? lastName,
    String? password,
    String? token,
    bool? isPublic,
    int? addressDetailId,
    AddressDetail? addressDetail,
  }) {
    return User(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      userType: userType ?? this.userType,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      password: password ?? this.password,
      token: token ?? this.token,
      isPublic: isPublic ?? this.isPublic,
      addressDetailId: addressDetailId ?? this.addressDetailId,
      addressDetail: addressDetail ?? this.addressDetail,
    );
  }
}
