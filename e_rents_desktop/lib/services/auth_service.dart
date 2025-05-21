import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:e_rents_desktop/models/auth/change_password_request_model.dart';
import 'package:e_rents_desktop/models/auth/forgot_password_request_model.dart';
import 'package:e_rents_desktop/models/auth/login_request_model.dart';
import 'package:e_rents_desktop/models/auth/login_response_model.dart';
import 'package:e_rents_desktop/models/auth/register_request_model.dart';
import 'package:e_rents_desktop/models/auth/reset_password_request_model.dart';
import 'package:e_rents_desktop/models/user.dart'; // Assuming User model exists
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';

class AuthService extends ApiService {
  AuthService(super.baseUrl, super.storageService);

  Future<LoginResponseModel> login(LoginRequestModel request) async {
    final response = await post('/Auth/Login', request.toJson());
    final jsonResponse = json.decode(response.body);
    final loginResponse = LoginResponseModel.fromJson(jsonResponse);
    await secureStorageService.storeToken(loginResponse.token);
    // Optionally store expiration or other details if needed
    return loginResponse;
  }

  Future<User> register(RegisterRequestModel request) async {
    final response = await post('/Auth/Register', request.toJson());
    final jsonResponse = json.decode(response.body);
    return User.fromJson(jsonResponse); // Assuming User.fromJson exists
  }

  Future<void> logout() async {
    await secureStorageService.clearToken();
    // Optionally call a backend logout endpoint if it exists
    // await post('/Auth/Logout', {});
  }

  Future<bool> isAuthenticated() async {
    final token = await secureStorageService.getToken();
    // Optionally, add token validation logic here (e.g., check expiration)
    return token != null;
  }

  Future<void> changePassword(ChangePasswordRequestModel request) async {
    await post('/Auth/ChangePassword', request.toJson(), authenticated: true);
  }

  Future<void> forgotPassword(ForgotPasswordRequestModel request) async {
    // The C# controller expects a raw JSON string for email, e.g., "user@example.com"
    final url = Uri.parse('$baseUrl/Auth/ForgotPassword');
    final headers = await getHeaders();
    // ApiService.getHeaders() sets Content-Type to application/json by default.
    // If it didn't, we would need to set it here:
    // headers['Content-Type'] = 'application/json';

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(request.email), // Send the email string, JSON encoded
    );

    // Manually handle response similar to ApiService._handleResponse
    if (response.statusCode >= 400) {
      String errorMessage;
      try {
        final errorJson = json.decode(response.body);
        errorMessage =
            errorJson['message'] ??
            'Unknown error occurred during forgot password';
      } catch (e) {
        errorMessage = 'Error: ${response.statusCode} during forgot password';
      }
      throw Exception(errorMessage);
    }
  }

  Future<void> resetPassword(ResetPasswordRequestModel request) async {
    await post('/Auth/ResetPassword', request.toJson());
  }

  Future<User> getMe() async {
    final response = await get('/Auth/Me', authenticated: true);
    final jsonResponse = json.decode(response.body);
    return User.fromJson(jsonResponse);
  }

  // getHeaders() is inherited from ApiService and will add the auth token.
  // _handleResponse is inherited from ApiService.
}
