import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/models/review.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';

/// Provider for managing property reviews
/// Handles loading, adding, and managing reviews for properties
class PropertyReviewsProvider extends BaseProvider {
  PropertyReviewsProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  List<Review> _reviews = [];
  List<Review> _allReviews = [];
  
  // Review search/filter state
  String _reviewSearchQuery = '';
  Map<String, dynamic> _reviewFilters = {};

  // ─── Getters ────────────────────────────────────────────────────────────
  List<Review> get reviews => _reviews;
  List<Review> get allReviews => _allReviews;
  String get reviewSearchQuery => _reviewSearchQuery;
  Map<String, dynamic> get reviewFilters => _reviewFilters;

  // ─── Public API ─────────────────────────────────────────────────────────
  
  /// Fetch reviews for a property
  Future<void> fetchReviews(int propertyId) async {
    final reviews = await executeWithState(() async {
      return await api.getListAndDecode('/reviews/property/$propertyId', Review.fromJson, authenticated: true);
    });

    if (reviews != null) {
      _allReviews = reviews;
      _reviews = List.from(_allReviews);
      _applyReviewSearchAndFilters();
    }
  }

  /// Add a new review
  Future<bool> addReview(int propertyId, String comment, double rating) async {
    final success = await executeWithStateForSuccess(() async {
      final newReview = await api.postAndDecode('/reviews', 
        {'propertyId': propertyId, 'comment': comment, 'rating': rating}, 
        Review.fromJson, authenticated: true);
      _allReviews.insert(0, newReview);
      _applyReviewSearchAndFilters();
    }, errorMessage: 'Failed to add review');

    return success;
  }

  /// Search reviews
  void searchReviews(String query) {
    _reviewSearchQuery = query;
    _applyReviewSearchAndFilters();
  }

  /// Apply filters to reviews
  void applyReviewFilters(Map<String, dynamic> filters) {
    _reviewFilters = Map.from(filters);
    _applyReviewSearchAndFilters();
  }

  /// Clear review search and filters
  void clearReviewSearchAndFilters() {
    _reviewSearchQuery = '';
    _reviewFilters.clear();
    _reviews = List.from(_allReviews);
    notifyListeners();
  }

  void _applyReviewSearchAndFilters() {
    _reviews = _allReviews.where((review) {
      // Apply search filter
      if (_reviewSearchQuery.isNotEmpty) {
        final query = _reviewSearchQuery.toLowerCase();
        if (!(review.description?.toLowerCase().contains(query) ?? false) &&
            !review.reviewTypeDisplay.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Apply other filters
      return _matchesReviewFilters(review, _reviewFilters);
    }).toList();
    
    notifyListeners();
  }

  bool _matchesReviewFilters(Review review, Map<String, dynamic> filters) {
    // Rating range filters
    if (filters.containsKey('minRating')) {
      final minRating = filters['minRating'] as double?;
      if (minRating != null && (review.starRating == null || review.starRating! < minRating)) {
        return false;
      }
    }
    
    if (filters.containsKey('maxRating')) {
      final maxRating = filters['maxRating'] as double?;
      if (maxRating != null && (review.starRating == null || review.starRating! > maxRating)) {
        return false;
      }
    }

    // Review type filter
    if (filters.containsKey('reviewType')) {
      final reviewType = filters['reviewType'] as ReviewType?;
      if (reviewType != null && review.reviewType != reviewType) return false;
    }

    // Verified filter
    if (filters.containsKey('isVerified')) {
      final isVerified = filters['isVerified'] as bool?;
      if (isVerified != null && review.isVerified != isVerified) return false;
    }

    return true;
  }
}
