import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/models/review_ui_model.dart';
import 'package:e_rents_mobile/feature/property_detail/widgets/property_reviews/review_item.dart';
import 'package:e_rents_mobile/core/widgets/elevated_text_button.dart';

class PropertyReviewsSection extends StatelessWidget {
  final List<ReviewUIModel> reviews;
  final double averageRating;

  const PropertyReviewsSection({
    super.key,
    required this.reviews,
    required this.averageRating,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ElevatedTextButton(
              text: 'See All (${reviews.length})',
              isCompact: true,
              onPressed: () {
                // Navigate to all reviews page
              },
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Rating summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < averageRating.floor()
                            ? Icons.star
                            : (index < averageRating
                                ? Icons.star_half
                                : Icons.star_border),
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                  ),
                  Text(
                    'Based on ${reviews.length} reviews',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar(context, 5, _calculatePercentage(5)),
                    _buildRatingBar(context, 4, _calculatePercentage(4)),
                    _buildRatingBar(context, 3, _calculatePercentage(3)),
                    _buildRatingBar(context, 2, _calculatePercentage(2)),
                    _buildRatingBar(context, 1, _calculatePercentage(1)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Review list
        ...reviews.take(3).map((review) => ReviewItem(review: review)),

        if (reviews.length > 3)
          Center(
            child: ElevatedTextButton(
              text: 'View All ${reviews.length} Reviews',
              onPressed: () {
                // Navigate to all reviews
              },
            ),
          ),
      ],
    );
  }

  double _calculatePercentage(int rating) {
    if (reviews.isEmpty) return 0.0;
    int count = reviews.where((review) => review.rating == rating).length;
    return count / reviews.length;
  }

  Widget _buildRatingBar(BuildContext context, int rating, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$rating',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 4),
          Icon(Icons.star, color: Colors.amber, size: 12),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                color: Colors.amber,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(percentage * 100).toInt()}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
