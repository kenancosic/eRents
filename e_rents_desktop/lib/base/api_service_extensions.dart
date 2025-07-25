import 'dart:convert';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/models/paged_result.dart';

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
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => decoder(json as Map<String, dynamic>)).toList();
  }
  
  /// GET request with automatic JSON decoding to PagedResult
  /// 
  /// Usage:
  /// ```dart
  /// final pagedUsers = await api.getPagedAndDecode('/users/paged', User.fromJson);
  /// ```
  Future<PagedResult<T>> getPagedAndDecode<T>(
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
    return PagedResult<T>.fromJson(data, (item) => decoder(item as Map<String, dynamic>));
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
  
  /// Standard desktop client headers
  Map<String, String> get desktopHeaders => const {'Client-Type': 'Desktop'};
}
