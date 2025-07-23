import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:e_rents_desktop/utils/logger.dart';

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

      try {
        final decodedBody = jsonDecode(response.body);
        errorMessage = decodedBody['message'] ?? decodedBody['error'] ?? 'An unknown error occurred.';
      } catch (e, stackTrace) {
        log.severe('ApiService: Failed to decode error response body', e, stackTrace);
        errorMessage = 'Failed to process server error response.';
      }

      log.severe('ApiService: Parsed error message: $errorMessage');
      throw Exception(errorMessage);
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

  // ======================================
  // CENTRALIZED IMAGE HANDLING UTILITIES
  // ======================================

  /// Returns true if the URL is an asset path (starts with 'assets/')
  bool isAssetPath(String url) {
    return url.startsWith('assets/');
  }

  /// Returns true if the URL is a network URL (contains protocol)
  bool isNetworkUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  /// Converts relative API URLs to absolute URLs using the configured base URL
  String makeAbsoluteUrl(String url) {
    if (url.isEmpty) return url;

    // If already absolute or an asset, return as-is
    if (isNetworkUrl(url) || isAssetPath(url)) {
      return url;
    }

    // It's a relative API path, so construct the full URL
    // Use Uri.parse().resolve() to correctly handle slashes.
    final absoluteUri = Uri.parse(baseUrl).resolve(url);
    final absoluteUrl = absoluteUri.toString();

    debugPrint(
      'ApiService: Converting relative URL "$url" to absolute: "$absoluteUrl"',
    );
    return absoluteUrl;
  }

  /// Creates the appropriate image widget based on the URL type
  /// Centralized image handling following architectural best practices
  Widget buildImage(
    String? imageUrl, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? errorWidget,
  }) {
    // Handle null or empty URLs with fallback
    if (imageUrl == null || imageUrl.isEmpty) {
      debugPrint('ApiService: Empty or null image URL provided');
      return errorWidget ?? _buildPlaceholderImage(width, height, 'No Image');
    }

    // Convert relative URLs to absolute URLs using centralized logic
    final fullUrl = makeAbsoluteUrl(imageUrl);
    debugPrint('ApiService: Original URL: "$imageUrl"');
    debugPrint('ApiService: Full URL: "$fullUrl"');
    debugPrint('ApiService: Base API URL: "$baseUrl"');

    if (isAssetPath(imageUrl)) {
      debugPrint('ApiService: Loading as asset image');
      return Image.asset(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('ApiService: Asset image failed to load: $error');
          return errorWidget ?? _buildErrorImage(width, height, 'Asset Error');
        },
      );
    } else {
      // Network image with proper loading and error handling
      debugPrint('ApiService: Loading as network image from: "$fullUrl"');
      return Image.network(
        fullUrl,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            debugPrint('ApiService: Image loaded successfully: "$fullUrl"');
            return child;
          }
          debugPrint(
            'ApiService: Loading image: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes ?? "unknown"} bytes',
          );
          return _buildLoadingImage(width, height);
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint(
            'ApiService: Network image failed to load from "$fullUrl": $error',
          );
          debugPrint('ApiService: Stack trace: $stackTrace');

          // Extract image ID from URL for better error display
          final imageId = _extractImageIdFromUrl(imageUrl);
          return errorWidget ??
              _buildErrorImage(width, height, 'ID: $imageId\nNot Found');
        },
      );
    }
  }

  /// Extract image ID from URL for error display
  String _extractImageIdFromUrl(String? url) {
    if (url == null) return 'Unknown';
    final match = RegExp(r'/Image/(\d+)').firstMatch(url);
    return match?.group(1) ?? 'Unknown';
  }

  /// Build a loading indicator image
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

  /// Build a placeholder image for missing images
  Widget _buildPlaceholderImage(double? width, double? height, String text) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            color: Colors.grey[500],
            size: (width != null && width < 100) ? 20 : 32,
          ),
          if ((width == null || width >= 60) &&
              (height == null || height >= 60))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: (width != null && width < 100) ? 8 : 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  /// Build an error image for failed loads
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
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  /// Creates the appropriate ImageProvider based on the URL type
  /// Centralized image provider handling following architectural best practices
  ImageProvider buildImageProvider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      debugPrint('ApiService: Empty or null image URL for provider');
      // Return a placeholder provider - 1x1 transparent gif
      return const NetworkImage(
        'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
      );
    }

    // Convert relative URLs to absolute URLs using centralized logic
    final fullUrl = makeAbsoluteUrl(imageUrl);

    if (isAssetPath(imageUrl)) {
      return AssetImage(imageUrl);
    } else {
      return NetworkImage(fullUrl);
    }
  }

  /// Test image URL availability (for debugging)
  Future<bool> testImageUrl(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return false;

    final fullUrl = makeAbsoluteUrl(imageUrl);
    debugPrint('ApiService: Testing image URL: "$fullUrl"');

    final completer = Completer<bool>();
    final image = NetworkImage(fullUrl);
    final stream = image.resolve(const ImageConfiguration());

    stream.addListener(ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {
        debugPrint('ApiService: Image URL test successful: "$fullUrl"');
        if (!completer.isCompleted) completer.complete(true);
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        debugPrint('ApiService: Image URL test failed: "$fullUrl" - Error: $exception');
        if (!completer.isCompleted) completer.complete(false);
      },
    ));

    return completer.future;
  }
}
