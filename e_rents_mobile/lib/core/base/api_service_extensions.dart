import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/models/paged_list.dart';

/// Extensions for ApiService to reduce boilerplate in providers
/// 
/// These extensions provide convenient methods for common API operations:
/// - Automatic JSON decoding with type safety
/// - List and paged result handling
/// - Error handling consistency
extension ApiServiceExtensions on ApiService {
  
  /// GET request with automatic JSON decoding to single object
  /// 
  /// Usage:
  /// ```dart
  /// final user = await api.getAndDecode('/users/1', User.fromJson);
  /// ```
  Future<T> getAndDecode<T>(
    String endpoint, 
    T Function(Map<String, dynamic>) decoder, {
    bool authenticated = false,
    Map<String, String>? customHeaders,
  }) async {
    final response = await get(
      endpoint, 
      authenticated: authenticated,
      customHeaders: customHeaders,
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    return decoder(data);
  }
  
  /// GET request with automatic JSON decoding to list of objects
  /// 
  /// Usage:
  /// ```dart
  /// final users = await api.getListAndDecode('/users', User.fromJson);
  /// ```
  Future<List<T>> getListAndDecode<T>(
    String endpoint, 
    T Function(Map<String, dynamic>) decoder, {
    bool authenticated = false,
    Map<String, String>? customHeaders,
  }) async {
    final response = await get(
      endpoint, 
      authenticated: authenticated,
      customHeaders: customHeaders,
    );
    final dynamic data = json.decode(response.body);
    
    // Handle both array and object responses
    if (data is List) {
      return data.map((json) => decoder(json as Map<String, dynamic>)).toList();
    } else if (data is Map<String, dynamic>) {
      // If the response is an object, try to find a list in common properties
      if (data.containsKey('items') && data['items'] is List) {
        return (data['items'] as List).map((json) => decoder(json as Map<String, dynamic>)).toList();
      } else if (data.containsKey('data') && data['data'] is List) {
        return (data['data'] as List).map((json) => decoder(json as Map<String, dynamic>)).toList();
      } else if (data.containsKey('results') && data['results'] is List) {
        return (data['results'] as List).map((json) => decoder(json as Map<String, dynamic>)).toList();
      } else {
        // If no list found in common properties, wrap the single object in a list
        return [decoder(data)];
      }
    } else {
      throw Exception('Unexpected response format: expected List or Map, got ${data.runtimeType}');
    }
  }
  
  /// GET request with automatic JSON decoding to PagedList (mobile equivalent of PagedResult)
  /// 
  /// Handles both paginated response format and simple array format from backend
  /// 
  /// Usage:
  /// ```dart
  /// final pagedUsers = await api.getPagedAndDecode('/users/paged', User.fromJson);
  /// ```
  Future<PagedList<T>> getPagedAndDecode<T>(
    String endpoint, 
    T Function(Map<String, dynamic>) decoder, {
    bool authenticated = false,
    Map<String, String>? customHeaders,
  }) async {
    final response = await get(
      endpoint, 
      authenticated: authenticated,
      customHeaders: customHeaders,
    );
    
    final dynamic decodedBody = json.decode(response.body);
    
    try {
      // Handle different response formats from backend
      if (decodedBody is List) {
        // Backend returned simple array - convert to PagedList format
        final items = decodedBody
            .cast<Map<String, dynamic>>()
            .map((item) => decoder(item))
            .toList();
        
        return PagedList<T>(
          items: items,
          totalCount: items.length,
          page: 1,
          pageSize: items.length,
        );
      } else if (decodedBody is Map<String, dynamic>) {
        // Check for common pagination response formats
        if (decodedBody.containsKey('items') && decodedBody['items'] is List) {
          // Standard pagination format
          final data = decodedBody['items'] as List;
          return PagedList<T>(
            items: data.cast<Map<String, dynamic>>().map(decoder).toList(),
            totalCount: decodedBody['totalCount'] as int? ?? data.length,
            page: decodedBody['page'] as int? ?? 1,
            pageSize: decodedBody['pageSize'] as int? ?? data.length,
          );
        } else if (decodedBody.containsKey('data') && decodedBody['data'] is List) {
          // Alternative format: { data: [], total: number, currentPage: number, perPage: number }
          final data = decodedBody['data'] as List;
          return PagedList<T>(
            items: data.cast<Map<String, dynamic>>().map(decoder).toList(),
            totalCount: decodedBody['total'] as int? ?? data.length,
            page: decodedBody['currentPage'] as int? ?? 1,
            pageSize: decodedBody['perPage'] as int? ?? data.length,
          );
        } else if (decodedBody.containsKey('results') && decodedBody['results'] is List) {
          // Another common format: { results: [], count: number, page: number, pageSize: number }
          final results = decodedBody['results'] as List;
          return PagedList<T>(
            items: results.cast<Map<String, dynamic>>().map(decoder).toList(),
            totalCount: decodedBody['count'] as int? ?? results.length,
            page: decodedBody['page'] as int? ?? 1,
            pageSize: decodedBody['pageSize'] as int? ?? results.length,
          );
        } else {
          // If it's a single object, wrap it in a list
          return PagedList<T>(
            items: [decoder(decodedBody)],
            totalCount: 1,
            page: 1,
            pageSize: 1,
          );
        }
      } else {
        throw Exception('Unexpected response format: expected List or Map, got ${decodedBody.runtimeType}');
      }
    } catch (e) {
      debugPrint('Error parsing paged response: $e');
      debugPrint('Response body: $decodedBody');
      rethrow;
    }
  }
  
  /// POST request with automatic JSON encoding/decoding
  /// 
  /// Usage:
  /// ```dart
  /// final user = await api.postAndDecode('/users', userData, User.fromJson);
  /// ```
  Future<T> postAndDecode<T>(
    String endpoint,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) decoder, {
    bool authenticated = false,
    Map<String, String>? customHeaders,
  }) async {
    final response = await post(
      endpoint,
      body,
      authenticated: authenticated,
      customHeaders: customHeaders,
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    return decoder(data);
  }
  
  /// POST request with automatic JSON decoding to list of objects
  ///
  /// Usage:
  /// ```dart
  /// final items = await api.postListAndDecode('/amenity/batch', {'ids': [1,2,3]}, Amenity.fromJson);
  /// ```
  Future<List<T>> postListAndDecode<T>(
    String endpoint,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) decoder, {
    bool authenticated = false,
    Map<String, String>? customHeaders,
  }) async {
    final response = await post(
      endpoint,
      body,
      authenticated: authenticated,
      customHeaders: customHeaders,
    );
    final dynamic data = json.decode(response.body);
    if (data is List) {
      return data.map((e) => decoder(e as Map<String, dynamic>)).toList();
    } else if (data is Map<String, dynamic>) {
      // Some APIs wrap list in a property
      if (data.containsKey('items') && data['items'] is List) {
        return (data['items'] as List).map((e) => decoder(e as Map<String, dynamic>)).toList();
      }
      if (data.containsKey('data') && data['data'] is List) {
        return (data['data'] as List).map((e) => decoder(e as Map<String, dynamic>)).toList();
      }
      // Fallback: single item wrapped
      return [decoder(data)];
    } else {
      throw Exception('Unexpected response format: expected List or Map, got ${data.runtimeType}');
    }
  }
  
  /// PUT request with automatic JSON encoding/decoding
  /// 
  /// Usage:
  /// ```dart
  /// final user = await api.putAndDecode('/users/1', userData, User.fromJson);
  /// ```
  Future<T> putAndDecode<T>(
    String endpoint,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) decoder, {
    bool authenticated = false,
    Map<String, String>? customHeaders,
  }) async {
    final response = await put(
      endpoint,
      body,
      authenticated: authenticated,
      customHeaders: customHeaders,
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    return decoder(data);
  }
  
  /// GET request that returns raw JSON map
  /// 
  /// Usage:
  /// ```dart
  /// final data = await api.getJson('/endpoint');
  /// ```
  Future<Map<String, dynamic>> getJson(
    String endpoint, {
    bool authenticated = false,
    Map<String, String>? customHeaders,
  }) async {
    final response = await get(
      endpoint, 
      authenticated: authenticated,
      customHeaders: customHeaders,
    );
    return json.decode(response.body) as Map<String, dynamic>;
  }
  
  /// POST request that returns raw JSON map
  /// 
  /// Usage:
  /// ```dart
  /// final data = await api.postJson('/endpoint', body);
  /// ```
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    bool authenticated = false,
    Map<String, String>? customHeaders,
  }) async {
    final response = await post(
      endpoint,
      body,
      authenticated: authenticated,
      customHeaders: customHeaders,
    );
    return json.decode(response.body) as Map<String, dynamic>;
  }
  
  /// PUT request that returns raw JSON map
  ///
  /// Usage:
  /// ```dart
  /// final data = await api.putJson('/endpoint', body);
  /// ```
  Future<Map<String, dynamic>> putJson(
    String endpoint,
    Map<String, dynamic> body, {
    bool authenticated = false,
    Map<String, String>? customHeaders,
  }) async {
    final response = await put(
      endpoint,
      body,
      authenticated: authenticated,
      customHeaders: customHeaders,
    );
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// DELETE request with success confirmation
  ///
  /// Usage:
  /// ```dart
  /// final success = await api.deleteAndConfirm('/users/1');
  /// ```
  Future<bool> deleteAndConfirm(
    String endpoint, {
    bool authenticated = false,
    Map<String, String>? customHeaders,
  }) async {
    try {
      await delete(
        endpoint,
        authenticated: authenticated,
        customHeaders: customHeaders,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Build query string from parameters
  /// 
  /// Usage:
  /// ```dart
  /// final endpoint = '/users${api.buildQueryString({'page': 1, 'limit': 10})}';
  /// ```
  String buildQueryString(Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return '';
    
    final queryParams = params.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}')
        .join('&');
    
    return queryParams.isEmpty ? '' : '?$queryParams';
  }
  
  /// Standard mobile client headers
  Map<String, String> get mobileHeaders => const {'Client-Type': 'Mobile'};
}