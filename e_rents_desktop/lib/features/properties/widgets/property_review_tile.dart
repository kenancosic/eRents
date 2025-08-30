import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:e_rents_desktop/models/review.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';

/// A reusable widget for displaying a property review with reply functionality
class PropertyReviewTile extends StatefulWidget {
  final Review review;
  final Future<void> Function(String text) onReply;

  const PropertyReviewTile({super.key, required this.review, required this.onReply});

  @override
  State<PropertyReviewTile> createState() => _PropertyReviewTileState();
}

class _PropertyReviewTileState extends State<PropertyReviewTile> {
  bool _expanded = false;

  Future<void> _promptReply(BuildContext context) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reply to review'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Write your response...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Send')),
        ],
      ),
    );
    if (text != null && text.isNotEmpty) {
      await widget.onReply(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.read<PropertyProvider>();
    final r = widget.review;
    final rating = r.starRating?.toStringAsFixed(1) ?? '';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        initiallyExpanded: false,
        onExpansionChanged: (open) async {
          setState(() => _expanded = open);
          if (open) {
            await prov.fetchReplies(r.reviewId);
          }
        },
        title: Row(
          children: [
            const Icon(Icons.reviews_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                r.description ?? '(no text)',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            if (rating.isNotEmpty) ...[
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(rating),
              const SizedBox(width: 12),
            ],
            Text(
              r.createdAt.toString(),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        trailing: TextButton.icon(
          onPressed: () => _promptReply(context),
          icon: const Icon(Icons.reply, size: 18),
          label: const Text('Reply'),
        ),
        children: [
          if ((r.replies ?? []).isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              child: Text(
                _expanded ? 'No replies yet.' : 'Expand to view replies',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final rep in r.replies!)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rep.description ?? '(no text)'),
                                const SizedBox(height: 2),
                                Text(
                                  rep.createdAt.toString(),
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
