import 'dart:convert';
import 'package:http/http.dart' as http;  // Ensure http is imported
import '../models/user.dart';
import 'secure_storage_service.dart';

class AuthService {
  final String _baseUrl = 'https://localhost:7193/';

  final SecureStorageService _secureStorageService;

  AuthService({required SecureStorageService secureStorageService}) : _secureStorageService = secureStorageService;

  Future<User> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = User.fromJson(data['user']);
      await _secureStorageService.writeToken('auth_token', data['token']);
      return user;
    } else {
      throw Exception('Failed to log in');
    }
  }

  Future<User> register(User user) async {
    final url = Uri.parse('$_baseUrl/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final registeredUser = User.fromJson(data['user']);
      await _secureStorageService.writeToken('auth_token', data['token']);
      return registeredUser;
    } else {
      throw Exception('Failed to register');
    }
  }

  Future<User> updateUser(User user) async {
    final token = await _secureStorageService.readToken('auth_token');
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

  Future<void> logout() async {
    await _secureStorageService.deleteToken('auth_token');
  }

  Future<User?> getCurrentUser() async {
    final token = await _secureStorageService.readToken('auth_token');
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

  Future<void> forgotPassword(String email) async {
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
  
   Future<User> getUserFromToken(String token) async {
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
      throw Exception('Failed to retrieve user from token');
    }
  }
}
