import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/services/secure_storage_service.dart';
import 'package:e_rents_mobile/core/widgets/property_image_placeholder.dart';
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
      'Client-Type': 'Mobile',
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
      } catch (e) {
        // Simple logging for mobile
        debugPrint('ApiService: Request failed (attempt ${retryCount + 1}/$maxRetries), Error: $e');
        
        // Check if this is a network connectivity issue
        if (e.toString().contains('SocketException') && e.toString().contains('semaphore timeout period has expired')) {
          if (retryCount + 1 == maxRetries) {
            throw Exception('Unable to connect to the server. Please check your internet connection and ensure the server is running.');
          }
        }
        
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

      debugPrint('ApiService: Error response status: ${response.statusCode}');
      debugPrint('ApiService: Error response body: ${response.body}');

      if (response.statusCode == 409) {
        throw Exception(
          'This item has been modified by another user. Please refresh and try again.',
        );
      }

      try {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody is Map<String, dynamic>) {
          errorMessage = decodedBody['message'] ?? decodedBody['error'] ?? decodedBody['title'] ?? 'Server error occurred.';
        } else {
          errorMessage = 'Unexpected server response format.';
        }
      } catch (e) {
        String rawError = response.body.trim();
        
        if (rawError.isEmpty) {
          errorMessage = 'HTTP ${response.statusCode}: ${_getStatusMessage(response.statusCode)}';
        } else if (rawError.toLowerCase().contains('<html>') || rawError.toLowerCase().contains('<!doctype')) {
          errorMessage = 'Server error (${response.statusCode}): The server returned an error page.';
        } else if (rawError.length > 200) {
          errorMessage = '${rawError.substring(0, 200)}...';
        } else {
          errorMessage = rawError;
        }
      }
      throw Exception(errorMessage);
    }
  }
  
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
          request.files.addAll(files);
        }

        final response = await http.Response.fromStream(await request.send());
        _handleResponse(response);
        return response;
      } catch (e) {
        debugPrint(
          'ApiService: Multipart request failed (attempt ${retryCount + 1}/$maxRetries), Error: $e');
        
        // Check if this is a network connectivity issue
        if (e.toString().contains('SocketException') && e.toString().contains('semaphore timeout period has expired')) {
          if (retryCount + 1 == maxRetries) {
            throw Exception('Unable to connect to the server. Please check your internet connection and ensure the server is running.');
          }
        }
        
        retryCount++;
        if (retryCount == maxRetries) {
          rethrow;
        }
        await Future.delayed(retryDelay);

        if (files != null && files.isNotEmpty) {
          rethrow;
        }
      }
    }
    throw Exception(
      'Failed to complete multipart request after $maxRetries attempts',
    );
  }

  bool isAssetPath(String url) {
    return url.startsWith('assets/');
  }

  bool isNetworkUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  String makeAbsoluteUrl(String url) {
    if (url.isEmpty) return url;
    if (isNetworkUrl(url) || isAssetPath(url)) {
      return url;
    }
    final absoluteUri = Uri.parse(baseUrl).resolve(url);
    return absoluteUri.toString();
  }

  Widget buildImage(
    String? imageUrl, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? errorWidget,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return errorWidget ?? _buildPlaceholderImage(width, height, 'No Image');
    }

    final fullUrl = makeAbsoluteUrl(imageUrl);

    if (isAssetPath(imageUrl)) {
      return Image.asset(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _buildErrorImage(width, height, 'Asset Error');
        },
      );
    } else {
      return Image.network(
        fullUrl,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return _buildLoadingImage(width, height);
        },
        errorBuilder: (context, error, stackTrace) {
          final imageId = _extractImageIdFromUrl(imageUrl);
          return errorWidget ??
              _buildErrorImage(width, height, 'ID: $imageId\nNot Found');
        },
      );
    }
  }

  String _extractImageIdFromUrl(String? url) {
    if (url == null) return 'Unknown';
    // Support both singular and plural route segments, absolute or relative URLs
    final match = RegExp(r'/(?:Image|Images)/(\d+)').firstMatch(url);
    if (match != null) return match.group(1) ?? 'Unknown';
    // Fallback: try query parameter pattern like ...?id=123
    final q = RegExp(r'[?&]id=(\d+)').firstMatch(url);
    return q?.group(1) ?? 'Unknown';
  }

  Widget _buildLoadingImage(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[100],
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(double? width, double? height, String text) {
    return PropertyImagePlaceholder(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(8),
    );
  }

  Widget _buildErrorImage(double? width, double? height, String text) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            color: Colors.red[400],
            size: (width != null && width < 100) ? 16 : 24,
          ),
          if ((width == null || width >= 60) &&
              (height == null || height >= 60))
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: (width != null && width < 100) ? 7 : 9,
                  fontWeight: FontWeight.w500
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  ImageProvider buildImageProvider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const NetworkImage(
        'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
      );
    }
    final fullUrl = makeAbsoluteUrl(imageUrl);
    if (isAssetPath(imageUrl)) {
      return AssetImage(imageUrl);
    } else {
      return NetworkImage(fullUrl);
    }
  }

  Future<bool> testImageUrl(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return false;
    final fullUrl = makeAbsoluteUrl(imageUrl);
    final completer = Completer<bool>();
    final image = NetworkImage(fullUrl);
    final stream = image.resolve(const ImageConfiguration());
    stream.addListener(ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {
        if (!completer.isCompleted) completer.complete(true);
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        if (!completer.isCompleted) completer.complete(false);
      },
    ));
    return completer.future;
  }
}
