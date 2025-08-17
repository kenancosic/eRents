import 'package:e_rents_desktop/models/enums/user_type.dart';

class RegisterRequestModel {
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String password;
  final String confirmPassword;
  final DateTime dateOfBirth;
  final UserType userType;

  const RegisterRequestModel({
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.confirmPassword,
    required this.dateOfBirth,
    required this.userType,
  });

  factory RegisterRequestModel.fromJson(Map<String, dynamic> json) {
    DateTime _reqDate(dynamic v) {
      final d = (v == null) ? null : (v is DateTime ? v : DateTime.tryParse(v.toString()));
      return d ?? DateTime.now();
    }
    String _str(dynamic v) => v?.toString() ?? '';
    return RegisterRequestModel(
      username: _str(json['username']),
      firstName: _str(json['firstName']),
      lastName: _str(json['lastName']),
      email: _str(json['email']),
      phoneNumber: _str(json['phoneNumber']),
      password: _str(json['password']),
      confirmPassword: _str(json['confirmPassword']),
      dateOfBirth: _reqDate(json['dateOfBirth']),
      userType: UserType.fromDynamic(json['userType']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
        'confirmPassword': confirmPassword,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'userType': userType.name,
      };
}