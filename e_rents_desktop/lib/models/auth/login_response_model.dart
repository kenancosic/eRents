import 'package:e_rents_desktop/models/user.dart';

class LoginResponseModel {
  final String token;
  final DateTime expiration;
  final User user;
  final String platform;

  const LoginResponseModel({
    required this.token,
    required this.expiration,
    required this.user,
    required this.platform,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    DateTime _reqDate(dynamic v) {
      final d = (v == null) ? null : (v is DateTime ? v : DateTime.tryParse(v.toString()));
      return d ?? DateTime.now();
    }
    String _str(dynamic v) => v?.toString() ?? '';
    return LoginResponseModel(
      token: _str(json['token']),
      expiration: _reqDate(json['expiration']),
      user: User.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
      platform: _str(json['platform']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'token': token,
        'expiration': expiration.toIso8601String(),
        'user': user.toJson(),
        'platform': platform,
      };
}
