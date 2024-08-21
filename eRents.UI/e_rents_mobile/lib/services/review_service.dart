import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/review.dart';

class ReviewService {
  final String _baseUrl = 'https://localhost:7193/api/reviews'; // Replace with your actual API URL

  // Fetch a review by ID
  Future<Review> getReviewById(int id) async {
    final url = Uri.parse('$_baseUrl/$id');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return Review.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load review');
    }
  }

  // Fetch all reviews or search reviews
  Future<List<Review>> getReviews({dynamic search}) async {
    final url = Uri.parse('$_baseUrl'); // Adjust with query parameters if needed
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Review.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load reviews');
    }
  }

  // Create a new review
  Future<Review> createReview(Review review) async {
    final url = Uri.parse('$_baseUrl');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(review.toJson()),
    );

    if (response.statusCode == 201) {
      return Review.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create review');
    }
  }

  // Update an existing review
  Future<Review> updateReview(int id, Review review) async {
    final url = Uri.parse('$_baseUrl/$id');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(review.toJson()),
    );

    if (response.statusCode == 200) {
      return Review.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update review');
    }
  }

  // Delete a review
  Future<bool> deleteReview(int id) async {
    final url = Uri.parse('$_baseUrl/$id');
    final response = await http.delete(url);

    if (response.statusCode == 204) {
      return true;
    } else {
      throw Exception('Failed to delete review');
    }
  }
}
