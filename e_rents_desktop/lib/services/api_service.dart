import 'dart:convert';
import 'package:e_rents_desktop/services/secure_storage_service.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  final SecureStorageService secureStorageService;
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  ApiService(this.baseUrl, this.secureStorageService);

  Future<Map<String, String>> getHeaders() async {
    final token = await secureStorageService.getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.Response> _request(
    String endpoint,
    String method,
    Map<String, dynamic>? body, {
    bool authenticated = false,
  }) async {
    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        final url = Uri.parse('$baseUrl$endpoint');
        final headers = await getHeaders();

        http.Response response;
        switch (method) {
          case 'POST':
            response = await http.post(
              url,
              headers: headers,
              body: jsonEncode(body),
            );
            break;
          case 'PUT':
            response = await http.put(
              url,
              headers: headers,
              body: jsonEncode(body),
            );
            break;
          case 'DELETE':
            response = await http.delete(url, headers: headers);
            break;
          default:
            response = await http.get(url, headers: headers);
        }

        _handleResponse(response);
        return response;
      } catch (e) {
        retryCount++;
        if (retryCount == maxRetries) {
          rethrow;
        }
        await Future.delayed(retryDelay);
      }
    }
    throw Exception('Failed to complete request after $maxRetries attempts');
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
      String errorMessage;
      try {
        final errorJson = json.decode(response.body);
        errorMessage = errorJson['message'] ?? 'Unknown error occurred';
      } catch (e) {
        errorMessage = 'Error: ${response.statusCode}';
      }
      throw Exception(errorMessage);
    }
  }
}
