import 'package:e_rents_mobile/models/user.dart';
import 'package:e_rents_mobile/providers/base_provider.dart';
import 'package:e_rents_mobile/services/local_storage_service.dart';
import 'dart:convert';
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
        await LocalStorageService.setItem('jwt_token', token);
        return true;
      }
      return false;
    } catch (e) {
      // Handle exception
      return false;
    }
  }

  Future<bool> signUp(String firstname, String lastname, String email, String password, String? userType) async {
    try {
      var headers = {'Content-Type': 'application/json'};
      var response = await http.post(
        Uri.parse('$baseUrl/Auth/Register'), // Replace with your actual signup endpoint
        headers: headers,
        body: jsonEncode({
          'firstname': firstname,
          'lastname': lastname,
          'email': email,
          'password': password,
          'userType': userType
        }),
      );

      if (response.statusCode == 201) {
        var data = jsonDecode(response.body);
        String token = data['token'];
        await LocalStorageService.setItem('jwt_token', token);
        return true;
      }
      return false;
    } catch (e) {
      // Handle exception
      return false;
    }
  }

  @override
  Future<Map<String, String>> createHeaders() async {
    String? jwt = LocalStorageService.getItem('jwt_token');
    if (jwt == null) {
      throw Exception('JWT token not found');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $jwt',
    };
  }

  // ... Other methods ...
}
