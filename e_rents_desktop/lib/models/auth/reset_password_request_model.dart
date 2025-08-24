class ResetPasswordRequestModel {
  final String email;
  final String resetCode;
  final String newPassword;
  final String confirmPassword;

  ResetPasswordRequestModel({
    required this.email,
    required this.resetCode,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'resetCode': resetCode,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };
  }
}