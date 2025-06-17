import 'package:e_rents_desktop/models/review.dart';
import 'package:e_rents_desktop/utils/date_utils.dart';
import 'package:flutter/material.dart';

class ReviewsList extends StatelessWidget {
  final List<Review> reviews;
  final bool isLoading;
  final String? error;
  final Function(int, String) onReplySubmitted;
  final VoidCallback? onLoadMore;
  final bool hasMoreReviews;
  final int totalCount;
  final bool canReply;

  const ReviewsList({
    super.key,
    required this.reviews,
    this.isLoading = false,
    this.error,
    required this.onReplySubmitted,
    this.onLoadMore,
    this.hasMoreReviews = false,
    this.totalCount = 0,
    this.canReply = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && reviews.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 8),
            Text('Error: $error'),
          ],
        ),
      );
    }

    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('No reviews yet.'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Review count header
          if (totalCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                'Showing ${reviews.length} of $totalCount reviews',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ),

          // Reviews list
          ...reviews.map((review) {
            try {
              return _ReviewItem(
                review: review,
                onReplySubmitted: onReplySubmitted,
                canReply: canReply,
              );
            } catch (e) {
              debugPrint(
                'Error building review item for review ${review.id}: $e',
              );
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text('Error loading review: ${e.toString()}'),
                ),
              );
            }
          }).toList(),

          // Load more button
          if (hasMoreReviews && onLoadMore != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onLoadMore,
                  icon:
                      isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.expand_more),
                  label: Text(isLoading ? 'Loading...' : 'Load More Reviews'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewItem extends StatefulWidget {
  final Review review;
  final Function(int, String) onReplySubmitted;
  final bool canReply;

  const _ReviewItem({
    required this.review,
    required this.onReplySubmitted,
    required this.canReply,
  });

  @override
  State<_ReviewItem> createState() => _ReviewItemState();
}

class _ReviewItemState extends State<_ReviewItem> {
  bool _isReplying = false;
  bool _isSubmittingReply = false;
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReviewHeader(),
            const SizedBox(height: 8),
            Text(widget.review.description),
            const SizedBox(height: 8),
            _buildReplySection(),
            if (_isReplying) _buildReplyForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewHeader() {
    return Row(
      children: [
        CircleAvatar(
          child: Text(widget.review.reviewerName?.substring(0, 1) ?? 'A'),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.review.reviewerName ?? 'Anonymous',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              AppDateUtils.formatRelative(widget.review.dateCreated),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const Spacer(),
        _buildRatingStars(),
      ],
    );
  }

  Widget _buildRatingStars() {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < (widget.review.starRating ?? 0)
              ? Icons.star
              : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  Widget _buildReplySection() {
    return Column(
      children: [
        for (var reply in widget.review.replies) _ReplyItem(reply: reply),
        if (widget.canReply && widget.review.isOriginalReview)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _isReplying = !_isReplying),
              child: Text(_isReplying ? 'Cancel' : 'Reply'),
            ),
          ),
      ],
    );
  }

  Widget _buildReplyForm() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              enabled: !_isSubmittingReply,
              decoration: const InputDecoration(
                hintText: 'Write a reply...',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
          ),
          IconButton(
            icon:
                _isSubmittingReply
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.send),
            onPressed: _isSubmittingReply ? null : _submitReply,
          ),
        ],
      ),
    );
  }

  Future<void> _submitReply() async {
    if (_replyController.text.isEmpty) return;

    setState(() => _isSubmittingReply = true);

    try {
      await widget.onReplySubmitted(widget.review.id, _replyController.text);

      if (mounted) {
        _replyController.clear();
        setState(() {
          _isReplying = false;
          _isSubmittingReply = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingReply = false);
        // Error handling is done in the parent widget
      }
    }
  }
}

class _ReplyItem extends StatelessWidget {
  final Review reply;

  const _ReplyItem({required this.reply});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(left: 40, top: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                reply.reviewerName ?? 'Anonymous',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                AppDateUtils.formatRelative(reply.dateCreated),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(reply.description),
        ],
      ),
    );
  }
}
