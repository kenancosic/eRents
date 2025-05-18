import 'package:meta/meta.dart';

class LoginResponseModel {
  final String token;
  final DateTime expiration;

  LoginResponseModel({required this.token, required this.expiration});

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      token: json['token'] as String,
      expiration: DateTime.parse(json['expiration'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {'token': token, 'expiration': expiration.toIso8601String()};
  }
}
