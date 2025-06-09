import 'package:flutter/material.dart';

class QuickActionsSection extends StatelessWidget {
  final VoidCallback? onExplorePressed;
  final VoidCallback? onSavedPressed;
  final VoidCallback? onBookingsPressed;
  final VoidCallback? onProfilePressed;

  const QuickActionsSection({
    super.key,
    this.onExplorePressed,
    this.onSavedPressed,
    this.onBookingsPressed,
    this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            'Explore',
            Icons.search,
            Colors.blue,
            onExplorePressed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            'Saved',
            Icons.favorite,
            Colors.red,
            onSavedPressed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            'Bookings',
            Icons.calendar_today,
            Colors.green,
            onBookingsPressed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            'Profile',
            Icons.person,
            Colors.orange,
            onProfilePressed,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
