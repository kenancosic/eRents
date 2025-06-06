import 'dart:convert';
import 'package:e_rents_desktop/services/secure_storage_service.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  final SecureStorageService secureStorageService;
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  ApiService(this.baseUrl, this.secureStorageService);

  Future<Map<String, String>> getHeaders({
    Map<String, String>? customHeaders,
  }) async {
    final token = await secureStorageService.getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Client-Type': 'Desktop',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    return headers;
  }

  Future<http.Response> _request(
    String endpoint,
    String method,
    Map<String, dynamic>? body, {
    bool authenticated = false,
    Map<String, String>? customHeaders,
  }) async {
    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        final url = Uri.parse('$baseUrl$endpoint');
        final headers = await getHeaders(customHeaders: customHeaders);

        http.Response response;
        switch (method) {
          case 'POST':
            response = await http.post(
              url,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            );
            break;
          case 'PUT':
            response = await http.put(
              url,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
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
        print(
          'ApiService: Request failed (attempt ${retryCount + 1}/$maxRetries): $e',
        );
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
    Map<String, String>? customHeaders,
  }) {
    return _request(
      endpoint,
      'POST',
      body,
      authenticated: authenticated,
      customHeaders: customHeaders,
    );
  }

  Future<http.Response> get(
    String endpoint, {
    bool authenticated = false,
    Map<String, String>? customHeaders,
  }) {
    return _request(
      endpoint,
      'GET',
      null,
      authenticated: authenticated,
      customHeaders: customHeaders,
    );
  }

  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool authenticated = false,
    Map<String, String>? customHeaders,
  }) {
    return _request(
      endpoint,
      'PUT',
      body,
      authenticated: authenticated,
      customHeaders: customHeaders,
    );
  }

  Future<http.Response> delete(
    String endpoint, {
    bool authenticated = false,
    Map<String, String>? customHeaders,
  }) {
    return _request(
      endpoint,
      'DELETE',
      null,
      authenticated: authenticated,
      customHeaders: customHeaders,
    );
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode >= 400) {
      String errorMessage;

      // Log the error details for debugging
      print('ApiService: Error response status: ${response.statusCode}');
      print('ApiService: Error response body: ${response.body}');

      // Handle concurrency conflicts (HTTP 409) with user-friendly message
      if (response.statusCode == 409) {
        print('ApiService: Concurrency conflict detected');
        throw Exception(
          'This item has been modified by another user. Please refresh and try again.',
        );
      }

      try {
        final errorJson = json.decode(response.body);
        errorMessage =
            errorJson['message'] ??
            errorJson['title'] ??
            errorJson['error'] ??
            'Server returned error ${response.statusCode}';
      } catch (e) {
        errorMessage =
            'Error: ${response.statusCode}. Response: ${response.body}';
      }

      print('ApiService: Parsed error message: $errorMessage');
      throw Exception(errorMessage);
    }
  }
}
