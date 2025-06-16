import 'package:e_rents_desktop/models/review.dart';
import 'package:e_rents_desktop/utils/date_utils.dart';
import 'package:flutter/material.dart';

class ReviewsList extends StatelessWidget {
  final List<Review> reviews;
  final bool isLoading;
  final String? error;
  final Function(int, String) onReplySubmitted;

  const ReviewsList({
    super.key,
    required this.reviews,
    this.isLoading = false,
    this.error,
    required this.onReplySubmitted,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
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

    return Column(
      children:
          reviews.map((review) {
            try {
              return _ReviewItem(
                review: review,
                onReplySubmitted: onReplySubmitted,
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
    );
  }
}

class _ReviewItem extends StatefulWidget {
  final Review review;
  final Function(int, String) onReplySubmitted;

  const _ReviewItem({required this.review, required this.onReplySubmitted});

  @override
  State<_ReviewItem> createState() => _ReviewItemState();
}

class _ReviewItemState extends State<_ReviewItem> {
  bool _isReplying = false;
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
              decoration: const InputDecoration(
                hintText: 'Write a reply...',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (_replyController.text.isNotEmpty) {
                widget.onReplySubmitted(
                  widget.review.id,
                  _replyController.text,
                );
                _replyController.clear();
                setState(() => _isReplying = false);
              }
            },
          ),
        ],
      ),
    );
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
