class LoginRequestModel {
  final String usernameOrEmail;
  final String password;
  final String clientType;

  LoginRequestModel({
    required this.usernameOrEmail,
    required this.password,
    this.clientType = 'Desktop'
  });

  Map<String, dynamic> toJson() {
    return {
      'usernameOrEmail': usernameOrEmail,
      'password': password,
      'clientType': clientType
    };
  }
}
