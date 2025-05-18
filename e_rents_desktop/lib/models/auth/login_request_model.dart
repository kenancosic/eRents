class LoginRequestModel {
  final String usernameOrEmail;
  final String password;

  LoginRequestModel({required this.usernameOrEmail, required this.password});

  Map<String, dynamic> toJson() {
    return {'usernameOrEmail': usernameOrEmail, 'password': password};
  }
}
