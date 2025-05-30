import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:e_rents_desktop/models/auth/change_password_request_model.dart';
import 'package:e_rents_desktop/models/auth/forgot_password_request_model.dart';
import 'package:e_rents_desktop/models/auth/login_request_model.dart';
import 'package:e_rents_desktop/models/auth/login_response_model.dart';
import 'package:e_rents_desktop/models/auth/register_request_model.dart';
import 'package:e_rents_desktop/models/auth/reset_password_request_model.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';

// TODO: Full backend integration for all auth features is pending.
// Ensure all endpoints are functional and error handling is robust.
class AuthService extends ApiService {
  AuthService(super.baseUrl, super.storageService);

  Future<LoginResponseModel> login(LoginRequestModel request) async {
    print('AuthService: Attempting to login...');
    final customHeaders = {'Client-Type': 'Desktop'};
    try {
      final response = await post(
        '/Auth/Login',
        request.toJson(),
        customHeaders: customHeaders,
      );
      final jsonResponse = json.decode(response.body);
      final loginResponse = LoginResponseModel.fromJson(jsonResponse);
      await secureStorageService.storeToken(loginResponse.token);
      print(
        'AuthService: Login successful, token stored. Verifying user info...',
      );

      // Verify user data after successful login
      // getMe() will throw if it fails, which will be caught by the outer catch block.
      final userInfo = await getMe();
      // The original check for userInfo or userInfo['User'] being null is good,
      // but getMe will now throw, simplifying this.
      print('AuthService: User info verified successfully after login.');
      return loginResponse;
    } catch (e) {
      print(
        'AuthService: Login failed or user verification failed: $e. Clearing token.',
      );
      await secureStorageService.clearToken();
      // Re-throw with a more specific message if it's a generic error from initial post
      // If e is already specific from getMe(), this might add less value but standardizes.
      if (e is! Exception ||
          !e.toString().contains('Backend integration pending')) {
        throw Exception(
          'Login failed. Backend integration might be pending or endpoint unavailable. Cause: $e',
        );
      }
      rethrow; // rethrow if it was already a specific exception from getMe()
    }
  }

  Future<Map<String, dynamic>> register(RegisterRequestModel request) async {
    print('AuthService: Attempting to register...');
    final customHeaders = {'Client-Type': 'Desktop'};
    try {
      final response = await post(
        '/Auth/Register',
        request.toJson(),
        customHeaders: customHeaders,
      );
      final jsonResponse = json.decode(response.body);
      print('AuthService: Registration request successful.');
      return jsonResponse;
    } catch (e) {
      print(
        'AuthService: Registration failed: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Registration failed. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<void> logout() async {
    print('AuthService: Logging out. Clearing token.');
    await secureStorageService.clearToken();
    // try {
    //   print('AuthService: Attempting to call backend logout...');
    //   await post('/Auth/Logout', {}, authenticated: true);
    //   print('AuthService: Backend logout successful.');
    // } catch (e) {
    //   print('AuthService: Error calling backend logout (optional operation): $e');
    //   // Do not throw an error here as logout should succeed client-side regardless.
    // }
  }

  Future<bool> isAuthenticated() async {
    final token = await secureStorageService.getToken();
    return token != null;
  }

  Future<void> changePassword(ChangePasswordRequestModel request) async {
    print('AuthService: Attempting to change password...');
    try {
      await post('/Auth/ChangePassword', request.toJson(), authenticated: true);
      print('AuthService: Change password request successful.');
    } catch (e) {
      print(
        'AuthService: Change password failed: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Change password failed. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<void> forgotPassword(ForgotPasswordRequestModel request) async {
    print('AuthService: Attempting forgot password for ${request.email}...');
    final url = Uri.parse('$baseUrl/Auth/ForgotPassword');
    try {
      final headers =
          await getHeaders(); // Should include Content-Type: application/json
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(request.email),
      );

      if (response.statusCode >= 400) {
        String errorMessage;
        try {
          final errorJson = json.decode(response.body);
          errorMessage =
              errorJson['message'] ?? 'Unknown error during forgot password';
        } catch (_) {
          errorMessage = 'Error: ${response.statusCode} during forgot password';
        }
        print('AuthService: Forgot password failed: $errorMessage');
        throw Exception(
          'Forgot password failed ($errorMessage). Backend integration might be pending or endpoint unavailable.',
        );
      }
      print(
        'AuthService: Forgot password request successful for ${request.email}.',
      );
    } catch (e) {
      print('AuthService: Forgot password failed: $e');
      if (e is! Exception ||
          !e.toString().contains('Backend integration pending')) {
        throw Exception(
          'Forgot password failed. Backend integration might be pending or endpoint unavailable. Cause: $e',
        );
      }
      rethrow;
    }
  }

  Future<void> resetPassword(ResetPasswordRequestModel request) async {
    print('AuthService: Attempting to reset password...');
    try {
      await post(
        '/Auth/ResetPassword',
        request.toJson(),
        authenticated: true,
      ); // Assuming reset needs auth if token is passed in body
      print('AuthService: Reset password request successful.');
    } catch (e) {
      print(
        'AuthService: Reset password failed: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Reset password failed. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    print('AuthService: Attempting to fetch current user (getMe)...');
    try {
      final response = await get('/Auth/Me', authenticated: true);
      // ApiService.get already throws for non-2xx/3xx responses.
      final jsonResponse = json.decode(response.body);
      print('AuthService: Successfully fetched current user (getMe).');
      return jsonResponse;
    } catch (e) {
      print(
        'AuthService: Error fetching current user (getMe): $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to fetch current user profile (getMe). Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  // getHeaders() is inherited from ApiService and will add the auth token.
  // _handleResponse is inherited from ApiService.
}
