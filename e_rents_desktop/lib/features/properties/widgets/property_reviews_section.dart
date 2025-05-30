import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/review.dart';
import 'package:e_rents_desktop/services/review_service.dart';
import 'package:intl/intl.dart';

class PropertyReviewsSection extends StatelessWidget {
  final PropertyReviewStats? reviewStats;
  final List<Review> reviews;

  const PropertyReviewsSection({
    super.key,
    this.reviewStats,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    if (reviewStats == null || reviews.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reviews',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.star_border, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No reviews yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reviews',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to all reviews
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildRatingOverview(),
                const SizedBox(width: 24),
                Expanded(child: _buildRecentReviews()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Text(
              reviewStats!.averageRating.toStringAsFixed(1),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            _buildStars(reviewStats!.averageRating),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${reviewStats!.totalReviews} review${reviewStats!.totalReviews != 1 ? 's' : ''}',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 20);
        } else if (index < rating) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 20);
        } else {
          return Icon(Icons.star_border, color: Colors.grey[400], size: 20);
        }
      }),
    );
  }

  Widget _buildRecentReviews() {
    final recentReviews = reviews.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Reviews',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        ...recentReviews.map((review) => _buildReviewItem(review)),
      ],
    );
  }

  Widget _buildReviewItem(Review review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStars(review.starRating),
                const Spacer(),
                Text(
                  DateFormat.yMMMd().format(review.dateReported),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              review.description,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
