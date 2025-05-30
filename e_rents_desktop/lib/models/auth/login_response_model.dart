import '../user.dart';

class LoginResponseModel {
  final String token;
  final DateTime expiration;
  final User user;
  final String platform;

  LoginResponseModel({
    required this.token,
    required this.expiration,
    required this.user,
    required this.platform,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      token: json['token'] as String,
      expiration: DateTime.parse(json['expiration'] as String),
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      platform: json['platform'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'expiration': expiration.toIso8601String(),
      'user': user.toJson(),
      'platform': platform,
    };
  }
}
