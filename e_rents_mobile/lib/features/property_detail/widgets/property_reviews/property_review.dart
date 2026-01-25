import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/models/review.dart';
import 'package:e_rents_mobile/features/property_detail/widgets/property_reviews/review_item.dart';
import 'package:e_rents_mobile/core/widgets/elevated_text_button.dart';

class PropertyReviewsSection extends StatelessWidget {
  final List<Review> reviews;
  final double averageRating;
  final int? propertyId;

  const PropertyReviewsSection({
    super.key,
    required this.reviews,
    required this.averageRating,
    this.propertyId,
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
              onPressed: () => _showAllReviews(context),
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
              onPressed: () => _showAllReviews(context),
            ),
          ),
      ],
    );
  }

  void _showAllReviews(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Reviews (${reviews.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Reviews list
              Expanded(
                child: reviews.isEmpty
                    ? Center(
                        child: Text(
                          'No reviews yet',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: reviews.length,
                        separatorBuilder: (context, index) => const Divider(height: 24),
                        itemBuilder: (context, index) => ReviewItem(review: reviews[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculatePercentage(int rating) {
    if (reviews.isEmpty) return 0.0;
    int count = reviews
        .where((review) => (review.starRating ?? 0.0).round() == rating)
        .length;
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
