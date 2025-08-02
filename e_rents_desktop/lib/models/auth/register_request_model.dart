class RegisterRequestModel {
  final String name;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String password;
  final String confirmPassword;
  final String dateOfBirth;
  final String role;

  RegisterRequestModel({
    required this.name,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.confirmPassword,
    required this.dateOfBirth,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': name,
      'firstName': name,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
      'userType': role,
      'dateOfBirth': dateOfBirth,
    };
  }
}