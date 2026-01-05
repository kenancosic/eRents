import 'package:flutter/material.dart';
import 'package:e_rents_desktop/features/notifications/providers/notification_provider.dart';
import 'package:e_rents_desktop/theme/theme.dart';
import 'package:intl/intl.dart';

/// A widget that displays a single notification item with type-specific styling
/// Designed for desktop layout with hover effects and more detailed display
class NotificationItem extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDelete;

  const NotificationItem({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.onDelete,
  });

  @override
  State<NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final typeInfo = _getTypeInfo(widget.notification.type);
    final isUnread = !widget.notification.isRead;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isHovered
              ? Colors.grey.shade50
              : (isUnread ? primaryColor.withValues(alpha: 0.03) : Colors.white),
          border: Border(
            left: BorderSide(
              color: isUnread ? primaryColor : Colors.transparent,
              width: 3,
            ),
            bottom: BorderSide(color: dividerColor, width: 1),
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: typeInfo.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    typeInfo.icon,
                    color: typeInfo.iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.notification.title ?? 'Notification',
                              style: TextStyle(
                                fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                                fontSize: 15,
                                color: textPrimaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildTypeBadge(typeInfo),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Message
                      Text(
                        widget.notification.message ?? '',
                        style: TextStyle(
                          color: textSecondaryColor,
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      // Footer: time and actions
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: textSecondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(widget.notification.createdAt),
                            style: TextStyle(
                              color: textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          // Actions (visible on hover)
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 150),
                            opacity: _isHovered ? 1.0 : 0.0,
                            child: Row(
                              children: [
                                if (isUnread)
                                  _buildActionButton(
                                    icon: Icons.done,
                                    tooltip: 'Mark as read',
                                    onPressed: widget.onMarkAsRead,
                                  ),
                                _buildActionButton(
                                  icon: Icons.delete_outline,
                                  tooltip: 'Delete',
                                  onPressed: widget.onDelete,
                                  color: Colors.red.shade400,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Unread indicator
                if (isUnread)
                  Container(
                    margin: const EdgeInsets.only(left: 12),
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: color ?? textSecondaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(_NotificationTypeInfo typeInfo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: typeInfo.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        typeInfo.label,
        style: TextStyle(
          color: typeInfo.iconColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  _NotificationTypeInfo _getTypeInfo(String? type) {
    switch (type?.toLowerCase()) {
      case 'booking':
        return _NotificationTypeInfo(
          icon: Icons.calendar_today_rounded,
          iconColor: const Color(0xFF3B82F6), // Blue
          backgroundColor: const Color(0xFFDBEAFE),
          label: 'Booking',
        );
      case 'payment':
        return _NotificationTypeInfo(
          icon: Icons.payment_rounded,
          iconColor: const Color(0xFF10B981), // Green
          backgroundColor: const Color(0xFFD1FAE5),
          label: 'Payment',
        );
      case 'maintenance':
        return _NotificationTypeInfo(
          icon: Icons.build_rounded,
          iconColor: const Color(0xFFF59E0B), // Amber
          backgroundColor: const Color(0xFFFEF3C7),
          label: 'Maintenance',
        );
      case 'review':
        return _NotificationTypeInfo(
          icon: Icons.star_rounded,
          iconColor: const Color(0xFFF59E0B), // Amber
          backgroundColor: const Color(0xFFFEF3C7),
          label: 'Review',
        );
      case 'property':
        return _NotificationTypeInfo(
          icon: Icons.home_rounded,
          iconColor: primaryColor,
          backgroundColor: accentLightColor,
          label: 'Property',
        );
      case 'message':
        return _NotificationTypeInfo(
          icon: Icons.chat_bubble_rounded,
          iconColor: const Color(0xFF3B82F6), // Blue
          backgroundColor: const Color(0xFFDBEAFE),
          label: 'Message',
        );
      case 'system':
      default:
        return _NotificationTypeInfo(
          icon: Icons.notifications_rounded,
          iconColor: textSecondaryColor,
          backgroundColor: Colors.grey.shade100,
          label: 'System',
        );
    }
  }
}

class _NotificationTypeInfo {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String label;

  _NotificationTypeInfo({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.label,
  });
}
