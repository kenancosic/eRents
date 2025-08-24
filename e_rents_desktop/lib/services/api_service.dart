import 'dart:async';
import 'dart:convert';
import 'package:e_rents_desktop/services/secure_storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:e_rents_desktop/utils/logger.dart';
import 'package:flutter/widgets.dart';

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
        // Ensure proper URL construction with forward slash
        final url = Uri.parse('${baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'}${endpoint.startsWith('/') ? endpoint.substring(1) : endpoint}');
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
      } catch (e, stackTrace) {
        log.warning(
          'ApiService: Request failed (attempt ${retryCount + 1}/$maxRetries)', e, stackTrace
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

  // Simple helper to POST arbitrary JSON-encodable bodies (e.g., arrays)
  Future<http.Response> postJson(
    String endpoint,
    Object body, {
    bool authenticated = false,
    Map<String, String>? customHeaders,
  }) async {
    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        final url = Uri.parse('${baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'}${endpoint.startsWith('/') ? endpoint.substring(1) : endpoint}');
        final headers = await getHeaders(customHeaders: customHeaders);
        final response = await http.post(
          url,
          headers: headers,
          body: jsonEncode(body),
        );
        _handleResponse(response);
        return response;
      } catch (e, stackTrace) {
        log.warning(
          'ApiService: postJson failed (attempt ${retryCount + 1}/$maxRetries)', e, stackTrace,
        );
        retryCount++;
        if (retryCount == maxRetries) rethrow;
        await Future.delayed(retryDelay);
      }
    }
    throw Exception('Failed to complete postJson after $maxRetries attempts');
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
      log.severe('ApiService: Error response status: ${response.statusCode}');
      log.severe('ApiService: Error response body: ${response.body}');

      // Handle concurrency conflicts (HTTP 409) with user-friendly message
      if (response.statusCode == 409) {
        log.warning('ApiService: Concurrency conflict detected');
        throw Exception(
          'This item has been modified by another user. Please refresh and try again.',
        );
      }

      // Try to parse as JSON first, fallback to plain text
      try {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody is Map<String, dynamic>) {
          if (decodedBody['errors'] is Map<String, dynamic>) {
            final errs = decodedBody['errors'] as Map<String, dynamic>;
            final parts = <String>[];
            errs.forEach((field, msgs) {
              if (msgs is List) {
                for (final m in msgs) {
                  parts.add('${field.toString()}: ${m.toString()}');
                }
              } else if (msgs != null) {
                parts.add('${field.toString()}: ${msgs.toString()}');
              }
            });
            if (parts.isNotEmpty) {
              errorMessage = parts.join('; ');
            } else {
              errorMessage = decodedBody['message'] ?? decodedBody['error'] ?? decodedBody['title'] ?? 'Server error occurred.';
            }
          } else {
            errorMessage = decodedBody['message'] ?? decodedBody['error'] ?? decodedBody['title'] ?? 'Server error occurred.';
          }
        } else {
          errorMessage = 'Unexpected server response format.';
        }
      } catch (e) {
        // JSON parsing failed - treat as plain text error
        log.info('ApiService: Non-JSON error response, using response body as error message');
        
        // Use response body directly, but clean it up if it's HTML or too long
        String rawError = response.body.trim();
        
        if (rawError.isEmpty) {
          errorMessage = 'HTTP ${response.statusCode}: ${_getStatusMessage(response.statusCode)}';
        } else if (rawError.toLowerCase().contains('<html>') || rawError.toLowerCase().contains('<!doctype')) {
          // HTML error page - extract title or use generic message
          errorMessage = 'Server error (${response.statusCode}): The server returned an error page.';
        } else if (rawError.length > 200) {
          // Truncate very long error messages
          errorMessage = '${rawError.substring(0, 200)}...';
        } else {
          errorMessage = rawError;
        }
      }

      log.severe('ApiService: Parsed error message: $errorMessage');
      throw Exception(errorMessage);
    }
  }
  
  /// Get human-readable status message for HTTP status codes
  String _getStatusMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 500:
        return 'Internal Server Error';
      case 502:
        return 'Bad Gateway';
      case 503:
        return 'Service Unavailable';
      default:
        return 'Unknown Error';
    }
  }

  Future<http.Response> multipartRequest(
    String endpoint,
    String method, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    bool authenticated = true,
    Map<String, String>? customHeaders,
  }) async {
    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        final url = Uri.parse('$baseUrl$endpoint');
        final request = http.MultipartRequest(method, url);
        final headers = await getHeaders(customHeaders: customHeaders);

        request.headers.addAll(headers);

        if (fields != null) {
          request.fields.addAll(fields);
        }

        if (files != null) {
          // ✅ FIXED: Create fresh MultipartFile instances for each retry attempt
          // to avoid "Can't finalize a finalized MultipartFile" errors
          request.files.addAll(files);
        }

        final response = await http.Response.fromStream(await request.send());
        _handleResponse(response);
        return response;
      } catch (e, stackTrace) {
        log.warning(
          'ApiService: Multipart request failed (attempt ${retryCount + 1}/$maxRetries)', e, stackTrace
        );
        retryCount++;
        if (retryCount == maxRetries) {
          rethrow;
        }
        await Future.delayed(retryDelay);

        // ✅ IMPORTANT: Do not retry multipart requests with files
        // MultipartFile objects can only be used once and cannot be finalized again
        if (files != null && files.isNotEmpty) {
          log.warning(
            'ApiService: Skipping retry for multipart request with files to avoid finalization error',
          );
          rethrow;
        }
      }
    }
    throw Exception(
      'Failed to complete multipart request after $maxRetries attempts',
    );
  }

  /// Build an Image widget from a URL or asset path, automatically applying
  /// authorization headers for network images via getHeaders().
  Widget buildImage(
    String pathOrUrl, {
    double? width,
    double? height,
    BoxFit? fit,
    Widget? errorWidget,
  }) {
    // Hard guard: never try to render backend Images API JSON endpoints via Image.network
    if (pathOrUrl.startsWith('/api/Images/') || pathOrUrl.contains('/api/Images/')) {
      log.warning('ApiService.buildImage: blocked rendering JSON endpoint $pathOrUrl');
      return SizedBox(
        width: width,
        height: height,
        child: const ColoredBox(color: Color(0xFFE0E0E0)),
      );
    }
    // Asset path
    if (isAssetPath(pathOrUrl)) {
      return Image.asset(
        pathOrUrl,
        width: width,
        height: height,
        fit: fit,
      );
    }

    // Compose absolute URL from baseUrl + endpoint
    final isAbsolute = pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://');
    final url = isAbsolute
        ? pathOrUrl
        : '${baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'}${pathOrUrl.startsWith('/') ? pathOrUrl.substring(1) : pathOrUrl}';

    // Headers are async; use FutureBuilder to retrieve them
    return FutureBuilder<Map<String, String>>(
      future: getHeaders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // lightweight placeholder to avoid layout jumps
          return SizedBox(
            width: width,
            height: height,
            child: const ColoredBox(color: Color(0xFFEAEAEA)),
          );
        }
        final headers = snapshot.data ?? const <String, String>{};
        return Image.network(
          url,
          headers: headers,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ?? SizedBox(
              width: width,
              height: height,
              child: const ColoredBox(color: Color(0xFFE0E0E0)),
            );
          },
        );
      },
    );
  }

  /// Returns true if the URL is an asset path (starts with 'assets/')
  bool isAssetPath(String url) {
    return url.startsWith('assets/');
  }
}