class ResetPasswordRequestModel {
  final String email;
  final String resetToken;
  final String newPassword;

  ResetPasswordRequestModel({
    required this.email,
    required this.resetToken,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'resetToken': resetToken,
      'newPassword': newPassword,
    };
  }
}