import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/features/notifications/providers/notification_provider.dart';
import 'package:e_rents_desktop/theme/theme.dart';

/// A notification bell icon with badge showing unread count
/// Designed for desktop navigation bars
/// 
/// Usage:
/// ```dart
/// Row(
///   children: [
///     NotificationBellBadge(),
///     // other actions
///   ],
/// )
/// ```
class NotificationBellBadge extends StatefulWidget {
  /// Icon size
  final double iconSize;
  
  /// Icon color (defaults to theme icon color)
  final Color? iconColor;
  
  /// Badge background color
  final Color badgeColor;
  
  /// Whether to use a compact style (for smaller spaces)
  final bool compact;

  const NotificationBellBadge({
    super.key,
    this.iconSize = 24,
    this.iconColor,
    this.compact = false,
    this.badgeColor = const Color(0xFFEF4444), // Red-500
  });

  @override
  State<NotificationBellBadge> createState() => _NotificationBellBadgeState();
}

class _NotificationBellBadgeState extends State<NotificationBellBadge> {
  @override
  void initState() {
    super.initState();
    // Load unread count on init
    Future.microtask(() {
      context.read<NotificationProvider>().loadUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final count = provider.unreadCount;

        if (widget.compact) {
          return _buildCompactButton(context, count);
        }

        return _buildFullButton(context, count);
      },
    );
  }

  Widget _buildCompactButton(BuildContext context, int count) {
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            count > 0 ? Icons.notifications : Icons.notifications_outlined,
            size: widget.iconSize,
            color: widget.iconColor ?? textSecondaryColor,
          ),
          if (count > 0)
            Positioned(
              right: -4,
              top: -4,
              child: _buildBadge(count),
            ),
        ],
      ),
      onPressed: () => context.go('/notifications'),
      tooltip: count > 0 ? '$count unread notifications' : 'Notifications',
    );
  }

  Widget _buildFullButton(BuildContext context, int count) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/notifications'),
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: count > 0 ? '$count unread notifications' : 'Notifications',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: count > 0 ? primaryColor.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      count > 0 ? Icons.notifications : Icons.notifications_outlined,
                      size: widget.iconSize,
                      color: count > 0 ? primaryColor : textSecondaryColor,
                    ),
                    if (count > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: _buildBadge(count),
                      ),
                  ],
                ),
                if (count > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(int count) {
    final displayCount = count > 99 ? '99+' : count.toString();
    final width = count > 99 ? 24.0 : (count > 9 ? 20.0 : 16.0);

    return Container(
      constraints: BoxConstraints(
        minWidth: width,
        minHeight: 16,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: widget.badgeColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: widget.badgeColor.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          displayCount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// Notification panel dropdown for quick access in app bars
/// Shows recent notifications in a dropdown menu
class NotificationDropdown extends StatefulWidget {
  const NotificationDropdown({super.key});

  @override
  State<NotificationDropdown> createState() => _NotificationDropdownState();
}

class _NotificationDropdownState extends State<NotificationDropdown> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<NotificationProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      tooltip: 'Notifications',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
      itemBuilder: (context) {
        final provider = context.read<NotificationProvider>();
        final notifications = provider.notifications.take(5).toList();

        return [
          // Header
          PopupMenuItem<String>(
            enabled: false,
            child: Row(
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textPrimaryColor,
                  ),
                ),
                const Spacer(),
                if (provider.unreadCount > 0)
                  TextButton(
                    onPressed: () {
                      provider.markAllAsRead();
                      Navigator.pop(context);
                    },
                    child: const Text('Mark all read'),
                  ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          // Notifications list
          if (notifications.isEmpty)
            const PopupMenuItem<String>(
              enabled: false,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No notifications',
                  style: TextStyle(color: textSecondaryColor),
                ),
              ),
            )
          else
            ...notifications.map((n) => PopupMenuItem<String>(
                  value: n.notificationId.toString(),
                  child: _buildNotificationItem(n),
                )),
          const PopupMenuDivider(),
          // View all link
          PopupMenuItem<String>(
            value: 'view_all',
            child: Center(
              child: Text(
                'View all notifications',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ];
      },
      onSelected: (value) {
        if (value == 'view_all') {
          context.go('/notifications');
        } else {
          // Handle individual notification tap
          final id = int.tryParse(value);
          if (id != null) {
            context.read<NotificationProvider>().markAsRead(id);
            context.go('/notifications');
          }
        }
      },
      child: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          final count = provider.unreadCount;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                count > 0 ? Icons.notifications : Icons.notifications_outlined,
                color: count > 0 ? primaryColor : textSecondaryColor,
              ),
              if (count > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      count > 9 ? '9+' : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.transparent : primaryColor.withValues(alpha: 0.05),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getTypeColor(notification.type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getTypeIcon(notification.type),
              size: 18,
              color: _getTypeColor(notification.type),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title ?? '',
                  style: TextStyle(
                    fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                    fontSize: 13,
                    color: textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  notification.message ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'booking':
        return Icons.calendar_today_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'maintenance':
        return Icons.build_rounded;
      case 'review':
        return Icons.star_rounded;
      case 'property':
        return Icons.home_rounded;
      case 'message':
        return Icons.chat_bubble_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'booking':
        return const Color(0xFF3B82F6);
      case 'payment':
        return const Color(0xFF10B981);
      case 'maintenance':
        return const Color(0xFFF59E0B);
      case 'review':
        return const Color(0xFFF59E0B);
      case 'property':
        return primaryColor;
      case 'message':
        return const Color(0xFF3B82F6);
      default:
        return textSecondaryColor;
    }
  }
}
