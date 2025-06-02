import 'package:e_rents_desktop/base/base.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/review.dart';
import 'package:e_rents_desktop/repositories/tenant_repository.dart';

/// Detail provider for individual tenant management
/// Handles single tenant details, feedbacks, and review operations
class TenantDetailProvider extends DetailProvider<User> {
  final TenantRepository _repository;

  // Tenant-specific data
  List<Review> _feedbacks = [];
  bool _isLoadingFeedbacks = false;

  TenantDetailProvider(this._repository)
    : super(_repository as Repository<User>);

  // Getters
  List<Review> get feedbacks => _feedbacks;
  bool get isLoadingFeedbacks => _isLoadingFeedbacks;

  /// Load tenant with feedbacks
  Future<void> loadTenantWithDetails(int tenantId) async {
    try {
      // Load basic tenant details
      await loadItem(tenantId.toString());

      // Load tenant feedbacks
      await loadTenantFeedbacks(tenantId);
    } catch (e) {
      rethrow;
    }
  }

  /// Load tenant feedbacks
  Future<void> loadTenantFeedbacks(int tenantId) async {
    _isLoadingFeedbacks = true;
    notifyListeners();

    try {
      _feedbacks = await _repository.getTenantFeedbacks(tenantId);
    } catch (e) {
      // Handle error but don't fail completely
      _feedbacks = [];
    } finally {
      _isLoadingFeedbacks = false;
      notifyListeners();
    }
  }

  /// Add feedback for tenant
  Future<void> addTenantFeedback(int tenantId, Review feedback) async {
    try {
      final newFeedback = await _repository.addTenantFeedback(
        tenantId,
        feedback,
      );
      _feedbacks.add(newFeedback);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Submit review for tenant
  Future<void> submitTenantReview({
    required int tenantId,
    required double rating,
    required String description,
  }) async {
    try {
      await _repository.submitReview(
        tenantId: tenantId,
        rating: rating,
        description: description,
      );

      // Refresh feedbacks after adding review
      await loadTenantFeedbacks(tenantId);
    } catch (e) {
      rethrow;
    }
  }

  /// Get average rating for current tenant
  double get averageRating {
    if (_feedbacks.isEmpty) return 0.0;

    final totalRating = _feedbacks.fold<double>(
      0.0,
      (sum, review) => sum + (review.starRating ?? 0.0),
    );
    return totalRating / _feedbacks.length;
  }

  /// Get recent feedbacks (last 30 days)
  List<Review> get recentFeedbacks {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _feedbacks
        .where((review) => review.dateCreated.isAfter(thirtyDaysAgo))
        .toList();
  }

  /// Get feedbacks by rating
  List<Review> getFeedbacksByRating(double minRating) {
    return _feedbacks
        .where((review) => (review.starRating ?? 0.0) >= minRating)
        .toList();
  }

  /// Clear tenant-specific data
  void clearTenantData() {
    _feedbacks.clear();
    _isLoadingFeedbacks = false;
    clear();
  }

  @override
  String _getItemId(User item) {
    return item.id.toString();
  }
}
