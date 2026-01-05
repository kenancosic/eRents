import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/models/notification.dart';
import 'package:e_rents_mobile/core/utils/app_colors.dart';
import 'package:e_rents_mobile/core/utils/app_spacing.dart';
import 'package:intl/intl.dart';

/// A widget that displays a single notification item with type-specific styling
class NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationItem({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final typeInfo = _getTypeInfo(notification.type);
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key('notification_${notification.notificationId}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: AppSpacing.paddingMD,
          decoration: BoxDecoration(
            color: isUnread ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.borderLight, width: 1),
              left: isUnread
                  ? BorderSide(color: AppColors.primary, width: 3)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeInfo.backgroundColor,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Icon(
                  typeInfo.icon,
                  color: typeInfo.iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

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
                            notification.title ?? 'Notification',
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Message
                    Text(
                      notification.message ?? '',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Time and type badge
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(notification.createdAt),
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _buildTypeBadge(typeInfo),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(_NotificationTypeInfo typeInfo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: typeInfo.backgroundColor,
        borderRadius: AppRadius.fullRadius,
      ),
      child: Text(
        typeInfo.label,
        style: TextStyle(
          color: typeInfo.iconColor,
          fontSize: 10,
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
      return DateFormat('MMM d').format(dateTime);
    }
  }

  _NotificationTypeInfo _getTypeInfo(String? type) {
    switch (type?.toLowerCase()) {
      case 'booking':
        return _NotificationTypeInfo(
          icon: Icons.calendar_today_rounded,
          iconColor: AppColors.info,
          backgroundColor: AppColors.infoLight,
          label: 'Booking',
        );
      case 'payment':
        return _NotificationTypeInfo(
          icon: Icons.payment_rounded,
          iconColor: AppColors.success,
          backgroundColor: AppColors.successLight,
          label: 'Payment',
        );
      case 'maintenance':
        return _NotificationTypeInfo(
          icon: Icons.build_rounded,
          iconColor: AppColors.warning,
          backgroundColor: AppColors.warningLight,
          label: 'Maintenance',
        );
      case 'review':
        return _NotificationTypeInfo(
          icon: Icons.star_rounded,
          iconColor: AppColors.warning,
          backgroundColor: AppColors.warningLight,
          label: 'Review',
        );
      case 'property':
        return _NotificationTypeInfo(
          icon: Icons.home_rounded,
          iconColor: AppColors.primary,
          backgroundColor: AppColors.accentLight,
          label: 'Property',
        );
      case 'message':
        return _NotificationTypeInfo(
          icon: Icons.chat_bubble_rounded,
          iconColor: AppColors.info,
          backgroundColor: AppColors.infoLight,
          label: 'Message',
        );
      case 'system':
      default:
        return _NotificationTypeInfo(
          icon: Icons.notifications_rounded,
          iconColor: AppColors.textSecondary,
          backgroundColor: AppColors.surfaceMedium,
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
