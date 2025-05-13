enum UserType { admin, landlord }

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
  final String? city;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? resetToken;
  final DateTime? resetTokenExpiration;

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
    this.city,
    required this.createdAt,
    required this.updatedAt,
    this.resetToken,
    this.resetTokenExpiration,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String?,
      role: UserType.values.firstWhere(
        (e) => e.toString() == 'UserType.${json['role']}',
        orElse: () => UserType.admin,
      ),
      profileImage: json['profileImage'] as String?,
      dateOfBirth:
          json['dateOfBirth'] != null
              ? DateTime.parse(json['dateOfBirth'] as String)
              : null,
      city: json['city'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      resetToken: json['resetToken'] as String?,
      resetTokenExpiration:
          json['resetTokenExpiration'] != null
              ? DateTime.parse(json['resetTokenExpiration'] as String)
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
      'city': city,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'resetToken': resetToken,
      'resetTokenExpiration': resetTokenExpiration?.toIso8601String(),
    };
  }

  String get fullName => '$firstName $lastName';

  /// Creates a copy of this User with the given fields replaced with the new values.
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
    String? city,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? resetToken,
    DateTime? resetTokenExpiration,
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
      city: city ?? this.city,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resetToken: resetToken ?? this.resetToken,
      resetTokenExpiration: resetTokenExpiration ?? this.resetTokenExpiration,
    );
  }
}
