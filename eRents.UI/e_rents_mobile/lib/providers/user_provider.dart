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
        Uri.parse('$baseUrl/Auth/Login'), // Endpoint for login on your API
        headers: headers,
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        // If server returns an OK response, parse the JSON
        var data = jsonDecode(response.body);
        String token =
            data['token']; // Assuming the token is returned with this key
        // Save the JWT token in local storage for later use in other requests
        await LocalStorageService.setItem('jwt_token', token);
        return true;
      }
      return false;
    } catch (e) {
      // Handle exception by logging or rethrowing
      return false;
    }
  }

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
