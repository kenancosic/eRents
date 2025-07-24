import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/services/secure_storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/models/review.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/models/maintenance_issue.dart';

class ApiService {
  final String baseUrl;
  final SecureStorageService secureStorageService;

  ApiService(this.baseUrl, this.secureStorageService);

  Future<http.Response> _request(
      String endpoint, String method, Map<String, dynamic>? body,
      {bool authenticated = false}) async {
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

  Future<http.Response> post(String endpoint, Map<String, dynamic> body,
      {bool authenticated = false}) {
    return _request(endpoint, 'POST', body, authenticated: authenticated);
  }

  Future<http.Response> get(String endpoint, {bool authenticated = false}) {
    return _request(endpoint, 'GET', null, authenticated: authenticated);
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body,
      {bool authenticated = false}) {
    return _request(endpoint, 'PUT', body, authenticated: authenticated);
  }

  Future<http.Response> delete(String endpoint, {bool authenticated = false}) {
    return _request(endpoint, 'DELETE', null, authenticated: authenticated);
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

    // If already absolute, return as-is
    if (isNetworkUrl(url) || isAssetPath(url)) {
      return url;
    }

    // If it's a relative API URL (starts with /), make it absolute
    if (url.startsWith('/')) {
      final absoluteUrl = '$baseUrl$url';
      debugPrint(
        'ApiService: Converting relative URL "$url" to absolute: "$absoluteUrl"',
      );
      return absoluteUrl;
    }

    return url;
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
      return errorWidget ??
          Icon(Icons.image, size: width ?? height ?? 64, color: Colors.grey);
    }

    // Convert relative URLs to absolute URLs using centralized logic
    final fullUrl = makeAbsoluteUrl(imageUrl);
    debugPrint('ApiService: Loading image from: "$fullUrl"');

    if (isAssetPath(imageUrl)) {
      return Image.asset(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('ApiService: Asset image failed to load: $error');
          return errorWidget ??
              Icon(
                Icons.broken_image,
                size: width ?? height ?? 64,
                color: Colors.grey,
              );
        },
      );
    } else {
      // Network image with proper loading and error handling
      return Image.network(
        fullUrl,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint(
            'ApiService: Network image failed to load from "$fullUrl": $error',
          );
          debugPrint('ApiService: Stack trace: $stackTrace');
          return errorWidget ??
              Icon(
                Icons.broken_image,
                size: width ?? height ?? 64,
                color: Colors.grey,
              );
        },
      );
    }
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

    try {
      final image = NetworkImage(fullUrl);
      final completer = image.resolve(const ImageConfiguration());
      debugPrint('ApiService: Image URL test successful: "$fullUrl"');
      return true;
    } catch (e) {
      debugPrint('ApiService: Image URL test failed: "$fullUrl" - Error: $e');
      return false;
    }
  }

  // ======================================
  // PROPERTY DETAIL METHODS
  // ======================================

  Future<Property> getPropertyById(String id) async {
    // TODO: Implement API call
    throw UnimplementedError('getPropertyById not implemented');
  }

  Future<List<Review>> getReviewsForProperty(String propertyId) async {
    // TODO: Implement API call
    throw UnimplementedError('getReviewsForProperty not implemented');
  }

  Future<List<MaintenanceIssue>> getMaintenanceIssuesForProperty(String propertyId) async {
    // TODO: Implement API call
    throw UnimplementedError('getMaintenanceIssuesForProperty not implemented');
  }

  Future<List<Property>> searchProperties(Map<String, dynamic> queryParams) async {
    // TODO: Implement API call
    throw UnimplementedError('searchProperties not implemented');
  }

  Future<Review> createReview(String propertyId, String comment, double rating) async {
    // TODO: Implement API call
    throw UnimplementedError('createReview not implemented');
  }

  Future<MaintenanceIssue> createMaintenanceIssue(String propertyId, String title, String description) {
    // TODO: Implement actual API call
    throw UnimplementedError();
  }

  Future<MaintenanceIssue> updateMaintenanceIssue(String issueId, Map<String, dynamic> updateData) {
    // TODO: Implement actual API call
    throw UnimplementedError();
  }

  Future<Booking> getBookingById(String bookingId) {
    // TODO: Implement actual API call
    throw UnimplementedError();
  }
}
