import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:e_rents_mobile/models/user.dart';
import 'package:e_rents_mobile/services/secure_storage_service.dart';

class AuthService {
  static const String _baseUrl = 'https://localhost:7193/';

  /// Logs in the user and stores the JWT token securely.
  static Future<User> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = User.fromJson(data['user']);
      await SecureStorageService.storeJwtToken(data['token']);
      return user;
    } else {
      throw Exception('Failed to log in');
    }
  }

  /// Registers a new user and stores the JWT token securely.
   static Future<User> register(User user) async {
    final url = Uri.parse('$_baseUrl/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        ...user.toJson()
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final registeredUser = User.fromJson(data['user']);
      await SecureStorageService.setItem('jwt_token', data['token']);
      return registeredUser;
    } else {
      throw Exception('Failed to register');
    }
  }

  static Future<User> updateUser(User user) async {
    final token = await SecureStorageService.getItem('jwt_token');
    final url = Uri.parse('$_baseUrl/users/${user.userId}');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else {
      throw Exception('Failed to update user');
    }
  }


  /// Logs out the user by removing the JWT token.
  static Future<void> logout() async {
    await SecureStorageService.removeJwtToken();
    // Optionally perform other cleanup actions here
  }

  /// Retrieves the current user's information using the stored JWT token.
  static Future<User?> getCurrentUser() async {
    final token = await SecureStorageService.getJwtToken();
    if (token == null) {
      return null; // No user is logged in
    }

    final url = Uri.parse('$_baseUrl/auth/me');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data['user']);
    } else {
      await logout();
      throw Exception('Failed to retrieve current user');
    }
  }

  static Future<void> forgotPassword(String email) async {
    final url = Uri.parse('$_baseUrl/auth/forgotpassword');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send reset link');
    }
  }
  
}
