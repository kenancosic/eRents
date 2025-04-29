import 'package:flutter/material.dart';

class TenantMatchScoreWidget extends StatelessWidget {
  final int score;

  const TenantMatchScoreWidget({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey.shade50,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getMatchScoreColor(score),
              ),
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$score%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: _getMatchScoreColor(score),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get color based on match score
  Color _getMatchScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.amber;
    return Colors.red;
  }
}
