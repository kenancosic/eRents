import './address_detail.dart';

enum UserType { admin, landlord, tenant }

class User {
  final String id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String? phone;
  final UserType role;
  final String? profileImage;
  final DateTime? dateOfBirth;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? resetToken;
  final DateTime? resetTokenExpiration;

  final String? addressDetailId;
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
      id: json['id'] as String? ?? json['userId']?.toString() ?? '',
      email: json['email'] as String,
      username: json['username'] as String,
      firstName: json['firstName'] as String? ?? json['name'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phone: json['phone'] as String? ?? json['phoneNumber'] as String?,
      role: UserType.values.firstWhere(
        (e) => e.toString() == 'UserType.${json['role'] ?? json['userType']}',
        orElse: () => UserType.admin,
      ),
      profileImage: json['profileImage'] as String?,
      dateOfBirth:
          json['dateOfBirth'] != null
              ? DateTime.parse(json['dateOfBirth'] as String)
              : null,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ??
            json['createdDate'] as String? ??
            DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ??
            json['updatedDate'] as String? ??
            DateTime.now().toIso8601String(),
      ),
      resetToken: json['resetToken'] as String?,
      resetTokenExpiration:
          json['resetTokenExpiration'] != null
              ? DateTime.parse(json['resetTokenExpiration'] as String)
              : null,
      isPaypalLinked: json['isPaypalLinked'] as bool? ?? false,
      paypalUserIdentifier: json['paypalUserIdentifier'] as String?,
      addressDetailId: json['addressDetailId']?.toString(),
      addressDetail:
          json['addressDetail'] != null
              ? AddressDetail.fromJson(
                json['addressDetail'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'role': role.toString().split('.').last,
      'profileImage': profileImage,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'resetToken': resetToken,
      'resetTokenExpiration': resetTokenExpiration?.toIso8601String(),
      'isPaypalLinked': isPaypalLinked,
      'paypalUserIdentifier': paypalUserIdentifier,
      'addressDetailId': addressDetailId,
    };
  }

  String get fullName => '$firstName $lastName';

  User copyWith({
    String? id,
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    String? phone,
    UserType? role,
    String? profileImage,
    DateTime? dateOfBirth,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? resetToken,
    DateTime? resetTokenExpiration,
    bool? isPaypalLinked,
    String? paypalUserIdentifier,
    String? addressDetailId,
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
