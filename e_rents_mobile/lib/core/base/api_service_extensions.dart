import 'dart:convert';
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
  }) async {
    final response = await get(
      endpoint, 
      authenticated: authenticated,
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
  }) async {
    final response = await get(
      endpoint, 
      authenticated: authenticated,
    );
    final data = json.decode(response.body) as List;
    return data.map((item) => decoder(item as Map<String, dynamic>)).toList();
  }
  
  /// GET request with automatic JSON decoding to PagedList
  /// 
  /// Usage:
  /// ```dart
  /// final pagedUsers = await api.getPagedAndDecode('/users', User.fromJson);
  /// ```
  Future<PagedList<T>> getPagedAndDecode<T>(
    String endpoint, 
    T Function(Map<String, dynamic>) decoder, {
    bool authenticated = false,
  }) async {
    final response = await get(
      endpoint, 
      authenticated: authenticated,
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    return PagedList<T>.fromJson(data, (json) => decoder(json as Map<String, dynamic>));
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
  }) async {
    final response = await post(
      endpoint, 
      body,
      authenticated: authenticated,
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
  }) async {
    final response = await put(
      endpoint, 
      body,
      authenticated: authenticated,
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    return decoder(data);
  }
  
  /// DELETE request with optional response decoding
  /// 
  /// Usage:
  /// ```dart
  /// await api.deleteAndDecode('/users/1'); // No response expected
  /// final result = await api.deleteAndDecode('/users/1', Result.fromJson); // With response
  /// ```
  Future<T?> deleteAndDecode<T>(
    String endpoint, [
    T Function(Map<String, dynamic>)? decoder,
  ]) async {
    final response = await delete(endpoint);
    
    if (decoder == null) return null;
    
    final data = json.decode(response.body) as Map<String, dynamic>;
    return decoder(data);
  }
  
  /// Build query parameters for GET requests
  /// 
  /// Usage:
  /// ```dart
  /// final endpoint = api.buildEndpointWithParams('/users', {'page': 1, 'limit': 10});
  /// ```
  String buildEndpointWithParams(String endpoint, Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return endpoint;
    
    final uri = Uri.parse(endpoint);
    final queryParams = params.map((key, value) => MapEntry(key, value.toString()));
    final newUri = uri.replace(queryParameters: {...uri.queryParameters, ...queryParams});
    
    return newUri.toString();
  }
  
  /// Helper method for search endpoints with common parameters
  /// 
  /// Usage:
  /// ```dart
  /// final properties = await api.searchAndDecode(
  ///   '/properties/search',
  ///   Property.fromJson,
  ///   query: 'apartment',
  ///   filters: {'city': 'New York', 'price_max': 2000},
  ///   page: 1,
  ///   pageSize: 20,
  /// );
  /// ```
  Future<PagedList<T>> searchAndDecode<T>(
    String baseEndpoint,
    T Function(Map<String, dynamic>) decoder, {
    String? query,
    Map<String, dynamic>? filters,
    int? page,
    int? pageSize,
    String? sortBy,
    String? sortOrder,
    bool authenticated = false,
    Map<String, String>? customHeaders,
  }) async {
    final params = <String, dynamic>{};
    
    if (query != null && query.isNotEmpty) params['FTS'] = query;
    if (filters != null) params.addAll(filters);
    if (page != null) params['Page'] = page;
    if (pageSize != null) params['PageSize'] = pageSize;
    if (sortBy != null) params['SortBy'] = sortBy;
    if (sortOrder != null) params['SortOrder'] = sortOrder;
    
    final endpoint = buildEndpointWithParams(baseEndpoint, params);
    return getPagedAndDecode(endpoint, decoder, authenticated: authenticated);
  }
}
