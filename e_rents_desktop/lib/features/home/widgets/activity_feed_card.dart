// import 'package:e_rents_desktop/models/recent_activity.dart'; // Deprecated model
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ActivityFeedCard extends StatelessWidget {
  // final List<RecentActivity> activities; // Deprecated model
  final List<dynamic> activities; // Temporary placeholder
  final String title;

  const ActivityFeedCard({
    super.key,
    required this.activities,
    this.title = 'Recent Activity',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (activities.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_none_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No recent activity to display.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // else
            //   ListView.separated(
            //     shrinkWrap: true,
            //     physics:
            //         const NeverScrollableScrollPhysics(), // if embedded in a scrollview
            //     itemCount: activities.length,
            //     itemBuilder: (context, index) {
            //       final activity = activities[index];
            //       return ListTile(
            //         leading: CircleAvatar(
            //           backgroundColor: theme.colorScheme.primaryContainer,
            //           child: Icon(
            //             activity.icon,
            //             color: theme.colorScheme.onPrimaryContainer,
            //             size: 20,
            //           ),
            //         ),
            //         title: Text(
            //           activity.title,
            //           style: theme.textTheme.titleMedium?.copyWith(
            //             fontSize: 15,
            //           ),
            //         ),
            //         subtitle:
            //             activity.subtitle != null
            //                 ? Text(
            //                   activity.subtitle!,
            //                   style: theme.textTheme.bodySmall,
            //                 )
            //                 : null,
            //         trailing: Text(
            //           _formatTimeAgo(activity.date),
            //           style: theme.textTheme.bodySmall?.copyWith(
            //             color: Colors.grey[600],
            //           ),
            //         ),
            //         onTap:
            //             activity.onTapRoute != null
            //                 ? () {
            //                   if (activity.onTapRouteParams != null) {
            //                     context.goNamed(
            //                       activity.onTapRoute!,
            //                       pathParameters: activity.onTapRouteParams!,
            //                     );
            //                   } else {
            //                     context.go(activity.onTapRoute!);
            //                   }
            //                 }
            //                 : null,
            //         dense: true,
            //       );
            //     },
            //     separatorBuilder: (context, index) => const Divider(height: 1),
            //   ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
