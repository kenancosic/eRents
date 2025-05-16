class User {
  final int? userId;
  final String username;
  final String email;
  final String? phoneNumber;
  final String? address;
  final String? city;
  final String? zipCode;
  final String? streetName;
  final String? streetNumber;
  final DateTime? dateOfBirth;
  final String? userType;
  final String? name;
  final String? lastName;
  final String? password;
  final String? token;
  final bool? isPublic;
  User({
    this.userId,
    required this.username,
    required this.email,
    this.phoneNumber,
    this.address,
    this.city,
    this.zipCode,
    this.streetName,
    this.streetNumber,
    this.dateOfBirth,
    this.userType,
    this.name,
    this.lastName,
    this.password,
    this.token,
    this.isPublic,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'],
      username: json['username'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      city: json['city'],
      zipCode: json['zipCode'],
      streetName: json['streetName'],
      streetNumber: json['streetNumber'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      userType: json['userType'],
      name: json['name'],
      lastName: json['lastName'],
      password: json['password'],
      token: json['resetToken'],
      isPublic: json['isPublic'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'city': city,
      'zipCode': zipCode,
      'streetName': streetName,
      'streetNumber': streetNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'userType': userType,
      'name': name,
      'lastName': lastName,
      'password': password,
      'resetToken': token,
      'isPublic': isPublic,
    };
  }

  User copyWith({
    int? userId,
    String? username,
    String? email,
    String? phoneNumber,
    String? address,
    String? city,
    String? zipCode,
    String? streetName,
    String? streetNumber,
    DateTime? dateOfBirth,
    String? userType,
    String? name,
    String? lastName,
    String? password,
    String? token,
    bool? isPublic,
  }) {
    return User(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      zipCode: zipCode ?? this.zipCode,
      streetName: streetName ?? this.streetName,
      streetNumber: streetNumber ?? this.streetNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      userType: userType ?? this.userType,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      password: password ?? this.password,
      token: token ?? this.token,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}
