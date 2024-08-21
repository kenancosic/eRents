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
    this.token
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
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth']) : null,
      userType: json['userType'],
      name: json['name'],
      lastName: json['lastName'],
      password: json['password'],
      token: json['resetToken']
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
      'resetToken': token
    };
  }
}
