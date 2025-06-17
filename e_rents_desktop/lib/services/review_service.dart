import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/models/review.dart';
import 'package:e_rents_desktop/models/property_stats_data.dart';

/// ✅ UNIVERSAL SYSTEM REVIEW SERVICE - Full Universal System Integration
///
/// This service provides review management using Universal System:
/// - Universal System pagination as default
/// - Non-paginated requests using noPaging=true parameter
/// - Property-specific reviews and statistics
/// - CRUD operations for review management
class ReviewService extends ApiService {
  ReviewService(super.baseUrl, super.storageService);

  String get endpoint => '/reviews';

  /// ✅ UNIVERSAL SYSTEM: Get paginated reviews with full filtering support
  /// DEFAULT METHOD - Uses pagination by default
  /// Matches: GET /reviews?page=1&pageSize=10&sortBy=StarRating&sortDesc=true
  Future<Map<String, dynamic>> getPagedReviews(
    Map<String, dynamic> params,
  ) async {
    try {
      // Build query string from params
      String queryString = '';
      if (params.isNotEmpty) {
        queryString =
            '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final response = await get('$endpoint$queryString', authenticated: true);
      return json.decode(response.body);
    } catch (e) {
      throw Exception('Failed to fetch paginated reviews: $e');
    }
  }

  /// ✅ UNIVERSAL SYSTEM: Get all reviews without pagination
  /// Uses noPaging=true for cases where all data is needed
  Future<List<Review>> getAllReviews([Map<String, dynamic>? params]) async {
    try {
      // Use Universal System with noPaging=true for all items
      final queryParams = <String, dynamic>{'noPaging': 'true', ...?params};

      String queryString = '';
      if (queryParams.isNotEmpty) {
        queryString =
            '?' +
            queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final response = await get('$endpoint$queryString', authenticated: true);
      final responseData = json.decode(response.body);

      // Handle Universal System response format
      List<dynamic> itemsJson;
      if (responseData is Map && responseData.containsKey('items')) {
        // Universal System response with noPaging=true
        itemsJson = responseData['items'] as List<dynamic>;
      } else if (responseData is List) {
        // Direct list response (fallback)
        itemsJson = responseData;
      } else {
        itemsJson = [];
      }

      return itemsJson.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch all reviews: $e');
    }
  }

  /// ✅ PROPERTY SPECIFIC: Get reviews for a specific property
  /// Uses Universal System filtering by propertyId
  Future<List<Review>> getPropertyReviews(String propertyId) async {
    debugPrint(
      'ReviewService: Attempting to fetch reviews for property $propertyId...',
    );
    try {
      // Use Universal System with propertyId filter and noPaging=true
      final reviews = await getAllReviews({'propertyId': propertyId});

      debugPrint(
        'ReviewService: Successfully fetched ${reviews.length} reviews for property $propertyId.',
      );
      return reviews;
    } catch (e) {
      debugPrint(
        'ReviewService: Error loading reviews for property $propertyId: $e',
      );
      return []; // Return empty list on error for backward compatibility
    }
  }

  /// ✅ PROPERTY SPECIFIC: Get paginated reviews for a specific property (NEW)
  /// Uses the new backend paginated endpoint for better performance
  Future<Map<String, dynamic>> getPagedPropertyReviews(
    String propertyId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    debugPrint(
      'ReviewService: Fetching page $page of reviews for property $propertyId (pageSize: $pageSize)...',
    );
    try {
      final response = await get(
        '$endpoint/property/$propertyId/paged?page=$page&pageSize=$pageSize',
        authenticated: true,
      );
      final responseData = json.decode(response.body);

      // Transform backend PagedList to frontend format
      final reviews =
          (responseData['items'] as List<dynamic>)
              .map((json) => Review.fromJson(json))
              .toList();

      debugPrint(
        'ReviewService: Successfully fetched page $page with ${reviews.length} reviews for property $propertyId.',
      );

      return {
        'reviews': reviews,
        'page': responseData['page'] ?? page,
        'pageSize': responseData['pageSize'] ?? pageSize,
        'totalCount': responseData['totalCount'] ?? 0,
        'totalPages': responseData['totalPages'] ?? 0,
        'hasNextPage': responseData['hasNextPage'] ?? false,
        'hasPreviousPage': responseData['hasPreviousPage'] ?? false,
      };
    } catch (e) {
      debugPrint(
        'ReviewService: Error loading paginated reviews for property $propertyId: $e',
      );
      return {
        'reviews': <Review>[],
        'page': page,
        'pageSize': pageSize,
        'totalCount': 0,
        'totalPages': 0,
        'hasNextPage': false,
        'hasPreviousPage': false,
      };
    }
  }

  /// ✅ UNIVERSAL SYSTEM: Get review count
  /// Uses Universal System count or extracts from paged response
  Future<int> getReviewCount([Map<String, dynamic>? params]) async {
    try {
      final queryParams = <String, dynamic>{
        'pageSize': 1, // Minimal page size, we only need count
        ...?params,
      };

      String queryString = '';
      if (queryParams.isNotEmpty) {
        queryString =
            '?' +
            queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final response = await get('$endpoint$queryString', authenticated: true);
      final responseData = json.decode(response.body);
      return responseData['totalCount'] ?? 0;
    } catch (e) {
      throw Exception('Failed to get review count: $e');
    }
  }

  /// ✅ CRUD: Get single review by ID
  /// Matches: GET /reviews/{id}
  Future<Review> getReviewById(String reviewId) async {
    try {
      final response = await get('$endpoint/$reviewId', authenticated: true);
      final responseData = json.decode(response.body);
      return Review.fromJson(responseData);
    } catch (e) {
      throw Exception('Failed to fetch review $reviewId: $e');
    }
  }

  /// ✅ CRUD: Create review
  /// Matches: POST /reviews
  Future<Review> createReview(Map<String, dynamic> request) async {
    try {
      final response = await post(endpoint, request, authenticated: true);
      final responseData = json.decode(response.body);
      return Review.fromJson(responseData);
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }

  /// ✅ CRUD: Update review
  /// Matches: PUT /reviews/{id}
  Future<Review> updateReview(
    String reviewId,
    Map<String, dynamic> request,
  ) async {
    try {
      final response = await put(
        '$endpoint/$reviewId',
        request,
        authenticated: true,
      );
      final responseData = json.decode(response.body);
      return Review.fromJson(responseData);
    } catch (e) {
      throw Exception('Failed to update review $reviewId: $e');
    }
  }

  /// ✅ CRUD: Delete review
  /// Matches: DELETE /reviews/{id}
  Future<bool> deleteReview(String reviewId) async {
    try {
      final response = await delete('$endpoint/$reviewId', authenticated: true);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to delete review $reviewId: $e');
    }
  }

  /// ✅ SPECIALIZED: Get property review statistics
  /// Matches: GET /reviews/{propertyId}/average-rating (specialized endpoint)
  Future<double> getAverageRating(String propertyId) async {
    debugPrint(
      'ReviewService: Attempting to fetch average rating for property $propertyId...',
    );
    try {
      final response = await get(
        '$endpoint/$propertyId/average-rating',
        authenticated: true,
      );
      final Map<String, dynamic> data = json.decode(response.body);

      final ratingValue = data['averageRating'];
      if (ratingValue == null) {
        debugPrint(
          'ReviewService: Average rating for property $propertyId was null from backend.',
        );
        throw Exception(
          'Failed to load average rating for property $propertyId: Backend returned null rating.',
        );
      }

      double parsedRating;
      if (ratingValue is num) {
        parsedRating = ratingValue.toDouble();
      } else if (ratingValue is String) {
        parsedRating =
            double.tryParse(ratingValue) ??
            -1.0; // Use -1 or throw to indicate parsing failure
        if (parsedRating == -1.0) {
          debugPrint(
            'ReviewService: Failed to parse average rating string "$ratingValue" for property $propertyId.',
          );
          throw Exception(
            'Failed to parse average rating string for property $propertyId: "$ratingValue"',
          );
        }
      } else {
        debugPrint(
          'ReviewService: Unexpected type for average rating "$ratingValue" for property $propertyId.',
        );
        throw Exception(
          'Unexpected data type for average rating for property $propertyId.',
        );
      }
      debugPrint(
        'ReviewService: Successfully fetched average rating $parsedRating for property $propertyId.',
      );
      return parsedRating;
    } catch (e) {
      debugPrint(
        'ReviewService: Error loading average rating for property $propertyId: $e',
      );
      throw Exception(
        'Failed to load average rating for property $propertyId: $e',
      );
    }
  }

  /// ✅ SPECIALIZED: Get property review statistics
  /// Note: This endpoint may be moved to PropertiesController in the future
  Future<PropertyReviewStats> getPropertyReviewStats(String propertyId) async {
    debugPrint(
      'ReviewService: Attempting to fetch review stats for property $propertyId...',
    );
    try {
      final response = await get(
        '/properties/$propertyId/review-stats',
        authenticated: true,
      );
      final Map<String, dynamic> data = json.decode(response.body);
      debugPrint(
        'ReviewService: Successfully fetched review stats for property $propertyId.',
      );
      return PropertyReviewStats.fromJson(data);
    } catch (e) {
      debugPrint(
        'ReviewService: Error loading review stats for property $propertyId: $e',
      );
      throw Exception(
        'Failed to load review stats for property $propertyId: $e',
      );
    }
  }

  /// ✅ SPECIALIZED: Create reply to a review
  /// Matches: POST /reviews (with parentReviewId)
  Future<Review> createReply({
    required int parentReviewId,
    required String description,
  }) async {
    try {
      final request = {
        'parentReviewId': parentReviewId,
        'description': description,
        'reviewType': 'PropertyReview', // Replies are property reviews
      };

      final response = await post(endpoint, request, authenticated: true);
      final responseData = json.decode(response.body);
      return Review.fromJson(responseData);
    } catch (e) {
      throw Exception('Failed to create reply: $e');
    }
  }

  /// ✅ SPECIALIZED: Get replies for a specific review
  /// Uses Universal System filtering by parentReviewId
  Future<List<Review>> getReviewReplies(int parentReviewId) async {
    try {
      final replies = await getAllReviews({'parentReviewId': parentReviewId});
      return replies;
    } catch (e) {
      debugPrint(
        'ReviewService: Error loading replies for review $parentReviewId: $e',
      );
      return [];
    }
  }
}
