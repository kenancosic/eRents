class RegisterRequestModel {
  final String? username;
  final String? email;
  final String? password;
  final String? confirmPassword;
  final String? address;
  final DateTime dateOfBirth;
  final String? phoneNumber;
  final String? name;
  final String? lastName;
  final String role;
  final String? profilePicture; // Assuming this might be a base64 string or URL

  RegisterRequestModel({
    this.username,
    this.email,
    this.password,
    this.confirmPassword,
    this.address,
    required this.dateOfBirth,
    this.phoneNumber,
    this.name,
    this.lastName,
    required this.role,
    this.profilePicture,
  });

  Map<String, dynamic> toJson() {
    return {
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      if (password != null) 'password': password,
      if (confirmPassword != null) 'confirmPassword': confirmPassword,
      if (address != null) 'address': address,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (name != null) 'name': name,
      if (lastName != null) 'lastName': lastName,
      'role': role,
      if (profilePicture != null) 'profilePicture': profilePicture,
    };
  }
}
