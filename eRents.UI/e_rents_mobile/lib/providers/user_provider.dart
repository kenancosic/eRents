import 'dart:convert';
import 'package:e_rents_mobile/models/user.dart';
import 'package:e_rents_mobile/providers/base_provider.dart';
import 'package:e_rents_mobile/services/secure_storage_service.dart';
import 'package:http/http.dart' as http;

class UserProvider extends BaseProvider<User> {
  UserProvider() : super("User");

  @override
  User fromJson(data) {
    return User.fromJson(data);
  }

  Future<bool> login(String email, String password) async {
    try {
      var headers = {'Content-Type': 'application/json'};
      var response = await http.post(
        Uri.parse('$baseUrl/Auth/Login'),
        headers: headers,
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        String token = data['token'];
        await SecureStorageService.setItem('jwt_token', token);
        await SecureStorageService.setItem('email', email);
        await SecureStorageService.setItem('password', password);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> signUp(String firstname, String surname, String username, String email, String password, String? role) async {
    try {
      var headers = {'Content-Type': 'application/json'};
      var response = await http.post(
        Uri.parse('$baseUrl/Auth/Register'),
        headers: headers,
        body: jsonEncode({
          'Firstname': firstname,
          'Surname': surname,
          'Username': username,
          'Email': email,
          'Password': password,
          'Role': role,
        }),
      );

      if (response.statusCode == 200) {
        // If registration is successful, attempt to log in automatically
        return await login(email, password);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      var headers = {'Content-Type': 'application/json'};
      var response = await http.post(
        Uri.parse('$baseUrl/Auth/ResetPassword'),
        headers: headers,
        body: jsonEncode({'email': email}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserRoles() async {
    try {
      var response = await http.get(Uri.parse('$baseUrl/Roles/GetRoleList'));

      if (response.statusCode == 200) {
        List<dynamic> roles = jsonDecode(response.body);
        return roles.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Map<String, String>> createHeaders() async {
    String? jwt = await SecureStorageService.getItem('jwt_token');
    if (jwt == null) {
      throw Exception('JWT token not found');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $jwt',
    };
  }
}
