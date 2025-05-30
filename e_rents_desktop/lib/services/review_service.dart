import 'dart:convert';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/models/review.dart';
import 'package:e_rents_desktop/models/booking_summary.dart'; // For PropertyReviewStats

// TODO: Full backend integration for all review features is pending.
// Ensure all endpoints are functional and error handling is robust.
class ReviewService extends ApiService {
  ReviewService(super.baseUrl, super.storageService);

  Future<List<Review>> getPropertyReviews(String propertyId) async {
    print(
      'ReviewService: Attempting to fetch reviews for property $propertyId...',
    );
    try {
      final response = await get(
        '/Reviews?PropertyId=$propertyId',
        authenticated: true,
      );
      final List<dynamic> data = json.decode(response.body);
      final List<Review> reviews = [];
      for (final item in data) {
        try {
          reviews.add(Review.fromJson(item));
        } catch (e) {
          print(
            'ReviewService: Error parsing a review item for property $propertyId: $e. Skipping this item.',
          );
          // Optionally, add a placeholder or skip, depending on UI handling needs.
          // For now, we skip the problematic review item.
        }
      }
      print(
        'ReviewService: Successfully fetched and parsed ${reviews.length} reviews for property $propertyId.',
      );
      return reviews;
    } catch (e) {
      print(
        'ReviewService: Error loading reviews for property $propertyId: $e. Backend integration might be pending or endpoint unavailable. Returning empty list.',
      );
      return []; // Return empty list on error or if backend is unavailable
    }
  }

  Future<PropertyReviewStats> getPropertyReviewStats(String propertyId) async {
    print(
      'ReviewService: Attempting to fetch review stats for property $propertyId...',
    );
    try {
      final response = await get(
        '/Properties/$propertyId/review-stats',
        authenticated: true,
      );
      final Map<String, dynamic> data = json.decode(response.body);
      print(
        'ReviewService: Successfully fetched review stats for property $propertyId.',
      );
      return PropertyReviewStats.fromJson(data);
    } catch (e) {
      print(
        'ReviewService: Error loading review stats for property $propertyId: $e. Backend integration might be pending or endpoint unavailable.',
      );
      // Throw an exception or return a specific error state object.
      // For now, throwing an exception to make the issue visible to the caller.
      throw Exception(
        'Failed to load review stats for property $propertyId. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<double> getAverageRating(String propertyId) async {
    print(
      'ReviewService: Attempting to fetch average rating for property $propertyId...',
    );
    try {
      final response = await get(
        '/Reviews/$propertyId/average-rating',
        authenticated: true,
      );
      final Map<String, dynamic> data = json.decode(response.body);

      final ratingValue = data['averageRating'];
      if (ratingValue == null) {
        print(
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
          print(
            'ReviewService: Failed to parse average rating string "$ratingValue" for property $propertyId.',
          );
          throw Exception(
            'Failed to parse average rating string for property $propertyId: "$ratingValue"',
          );
        }
      } else {
        print(
          'ReviewService: Unexpected type for average rating "$ratingValue" for property $propertyId.',
        );
        throw Exception(
          'Unexpected data type for average rating for property $propertyId.',
        );
      }
      print(
        'ReviewService: Successfully fetched average rating $parsedRating for property $propertyId.',
      );
      return parsedRating;
    } catch (e) {
      print(
        'ReviewService: Error loading average rating for property $propertyId: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to load average rating for property $propertyId. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }
}
