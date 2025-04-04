import 'dart:convert';
import 'package:e_rents_desktop/services/secure_storage_service.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  final SecureStorageService secureStorageService;

  ApiService(this.baseUrl, this.secureStorageService);

  Future<Map<String, String>> getHeaders() async {
    return {'Content-Type': 'application/json', 'Accept': 'application/json'};
  }

  Future<http.Response> _request(
    String endpoint,
    String method,
    Map<String, dynamic>? body, {
    bool authenticated = false,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    Map<String, String> headers = {'Content-Type': 'application/json'};

    if (authenticated) {
      final token = await secureStorageService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    switch (method) {
      case 'POST':
        return await http.post(url, headers: headers, body: jsonEncode(body));
      case 'PUT':
        return await http.put(url, headers: headers, body: jsonEncode(body));
      case 'DELETE':
        return await http.delete(url, headers: headers);
      default:
        return await http.get(url, headers: headers);
    }
  }

  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) {
    return _request(endpoint, 'POST', body, authenticated: authenticated);
  }

  Future<http.Response> get(String endpoint, {bool authenticated = false}) {
    return _request(endpoint, 'GET', null, authenticated: authenticated);
  }

  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) {
    return _request(endpoint, 'PUT', body, authenticated: authenticated);
  }

  Future<http.Response> delete(String endpoint, {bool authenticated = false}) {
    return _request(endpoint, 'DELETE', null, authenticated: authenticated);
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode >= 400) {
      throw Exception('API Error: ${response.statusCode}');
    }
  }
}
