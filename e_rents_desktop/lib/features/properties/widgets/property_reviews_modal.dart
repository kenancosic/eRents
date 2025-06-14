import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:e_rents_desktop/models/review.dart';
import 'package:e_rents_desktop/services/review_service.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:e_rents_desktop/base/service_locator.dart';
import 'package:e_rents_desktop/widgets/loading_or_error_widget.dart';

class PropertyReviewsModal extends StatefulWidget {
  final int propertyId;
  final String propertyName;

  const PropertyReviewsModal({
    super.key,
    required this.propertyId,
    required this.propertyName,
  });

  @override
  State<PropertyReviewsModal> createState() => _PropertyReviewsModalState();
}

class _PropertyReviewsModalState extends State<PropertyReviewsModal> {
  late ReviewService _reviewService;
  List<Review> _reviews = [];
  bool _isLoading = true;
  String? _error;
  final Map<int, bool> _showReplies = {};
  final Map<int, bool> _showReplyForm = {};
  final Map<int, TextEditingController> _replyControllers = {};

  @override
  void initState() {
    super.initState();
    _reviewService = getService<ReviewService>();
    _loadReviews();
  }

  @override
  void dispose() {
    for (final controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reviews = await _reviewService.getPropertyReviews(
        widget.propertyId.toString(),
      );

      // Only show original reviews (not replies) at the top level
      final originalReviews =
          reviews.where((review) => review.isOriginalReview).toList();

      // Sort by date (newest first)
      originalReviews.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));

      // Load replies for each review
      for (final review in originalReviews) {
        try {
          final replies = await _reviewService.getReviewReplies(review.id);
          // Update the review's replies list
          final updatedReview = Review(
            id: review.id,
            reviewType: review.reviewType,
            propertyId: review.propertyId,
            revieweeId: review.revieweeId,
            reviewerId: review.reviewerId,
            bookingId: review.bookingId,
            starRating: review.starRating,
            description: review.description,
            dateCreated: review.dateCreated,
            parentReviewId: review.parentReviewId,
            imageIds: review.imageIds,
            replies: replies,
            replyCount: replies.length,
            userFirstNameReviewer: review.userFirstNameReviewer,
            userLastNameReviewer: review.userLastNameReviewer,
            userFirstNameReviewee: review.userFirstNameReviewee,
            userLastNameReviewee: review.userLastNameReviewee,
            propertyName: review.propertyName,
          );

          // Replace the review in the list
          final index = originalReviews.indexOf(review);
          if (index >= 0) {
            originalReviews[index] = updatedReview;
          }
        } catch (e) {
          print('Error loading replies for review ${review.id}: $e');
        }
      }

      setState(() {
        _reviews = originalReviews;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createReply(int parentReviewId, String description) async {
    try {
      await _reviewService.createReply(
        parentReviewId: parentReviewId,
        description: description,
      );

      // Clear the reply form
      _replyControllers[parentReviewId]?.clear();
      setState(() {
        _showReplyForm[parentReviewId] = false;
      });

      // Reload reviews to show the new reply
      await _loadReviews();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post reply: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reviews for ${widget.propertyName}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_reviews.length} review${_reviews.length != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: LoadingOrErrorWidget(
                isLoading: _isLoading,
                error: _error,
                onRetry: _loadReviews,
                child:
                    _reviews.isEmpty ? _buildEmptyState() : _buildReviewsList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No reviews yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Reviews from guests will appear here',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return ListView.separated(
      itemCount: _reviews.length,
      separatorBuilder: (context, index) => const Divider(height: 32),
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return _buildReviewItem(review);
      },
    );
  }

  Widget _buildReviewItem(Review review) {
    final showReplies = _showReplies[review.id] ?? false;
    final showReplyForm = _showReplyForm[review.id] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Original Review
        _buildReviewCard(review, isReply: false),

        // Replies Section
        if (review.hasReplies || showReplyForm) ...[
          const SizedBox(height: 12),

          // Show/Hide Replies Button
          if (review.hasReplies)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showReplies[review.id] = !showReplies;
                });
              },
              icon: Icon(showReplies ? Icons.expand_less : Icons.expand_more),
              label: Text(
                showReplies
                    ? 'Hide ${review.replies.length} repl${review.replies.length == 1 ? 'y' : 'ies'}'
                    : 'Show ${review.replies.length} repl${review.replies.length == 1 ? 'y' : 'ies'}',
              ),
            ),

          // Replies List
          if (showReplies && review.hasReplies)
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Column(
                children:
                    review.replies
                        .map(
                          (reply) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildReviewCard(reply, isReply: true),
                          ),
                        )
                        .toList(),
              ),
            ),

          // Reply Form
          if (showReplyForm) _buildReplyForm(review),

          // Reply Button
          if (!showReplyForm)
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final currentUser = authProvider.currentUser;
                if (currentUser?.role?.name != 'Landlord') {
                  return const SizedBox.shrink();
                }

                return TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showReplyForm[review.id] = true;
                      _replyControllers[review.id] ??= TextEditingController();
                    });
                  },
                  icon: const Icon(Icons.reply),
                  label: const Text('Reply'),
                );
              },
            ),
        ],
      ],
    );
  }

  Widget _buildReviewCard(Review review, {required bool isReply}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isReply ? Colors.grey[50] : Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    isReply ? Colors.orange[100] : Colors.blue[100],
                child: Text(
                  _getInitials(review.reviewerName ?? 'User'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isReply ? Colors.orange[700] : Colors.blue[700],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.reviewerName ?? 'Anonymous',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (isReply) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Property Owner',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      DateFormat('MMM d, yyyy').format(review.dateCreated),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (review.hasRating)
                Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber[600]),
                    const SizedBox(width: 4),
                    Text(
                      review.starRating!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Review Content
          Text(
            review.description,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyForm(Review parentReview) {
    final controller = _replyControllers[parentReview.id]!;

    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          border: Border.all(color: Colors.blue[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reply to this review',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write your reply...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    controller.clear();
                    setState(() {
                      _showReplyForm[parentReview.id] = false;
                    });
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isNotEmpty) {
                      _createReply(parentReview.id, text);
                    }
                  },
                  child: const Text('Post Reply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return 'U';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
}
