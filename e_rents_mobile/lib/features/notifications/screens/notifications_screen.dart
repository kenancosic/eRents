import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_mobile/features/notifications/providers/notification_provider.dart';
import 'package:e_rents_mobile/features/notifications/widgets/notification_item.dart';
import 'package:e_rents_mobile/features/profile/providers/user_bookings_provider.dart';
import 'package:e_rents_mobile/features/profile/providers/invoices_provider.dart';
import 'package:e_rents_mobile/core/providers/current_user_provider.dart';
import 'package:e_rents_mobile/core/utils/app_colors.dart';
import 'package:e_rents_mobile/core/utils/app_spacing.dart';
import 'package:e_rents_mobile/core/models/notification.dart';

/// Main notifications screen displaying all user notifications
/// 
/// Features:
/// - Pull-to-refresh
/// - Swipe-to-delete
/// - Mark all as read
/// - Infinite scroll pagination
/// - Empty state
/// - Navigation to related content on tap
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    Future.microtask(() {
      if (!mounted) return;
      context.read<NotificationProvider>().refresh();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount > 0) {
                return TextButton.icon(
                  onPressed: () => _markAllAsRead(context),
                  icon: const Icon(Icons.done_all, size: 20),
                  label: const Text('Mark all read'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          // Loading state
          if (provider.isLoading && provider.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error state
          if (provider.hasError && provider.isEmpty) {
            return _buildErrorState(context, provider);
          }

          // Empty state
          if (provider.isEmpty) {
            return _buildEmptyState(context);
          }

          // Content
          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            color: AppColors.primary,
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: provider.notifications.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                // Loading indicator at bottom
                if (index >= provider.notifications.length) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }

                final notification = provider.notifications[index];
                return NotificationItem(
                  notification: notification,
                  onTap: () => _handleNotificationTap(context, notification),
                  onDismiss: () => _deleteNotification(context, notification),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingXL,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceMedium,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 40,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No notifications yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'When you receive notifications about bookings,\npayments, or messages, they\'ll appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, NotificationProvider provider) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingXL,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              provider.errorMessage.isNotEmpty 
                  ? provider.errorMessage 
                  : 'Unable to load notifications',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAllAsRead(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final provider = context.read<NotificationProvider>();
    final success = await provider.markAllAsRead();
    
    if (!mounted) return;
    
    if (success) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteNotification(BuildContext context, AppNotification notification) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final provider = context.read<NotificationProvider>();
    final success = await provider.deleteNotification(notification.notificationId);
    
    if (!mounted) return;
    
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(success ? 'Notification deleted' : 'Failed to delete notification'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, AppNotification notification) {
    // Mark as read first
    if (!notification.isRead) {
      context.read<NotificationProvider>().markAsRead(notification.notificationId);
    }

    // Navigate based on notification type
    final type = notification.type?.toLowerCase();
    
    switch (type) {
      case 'booking':
      case 'lease_extension':
        // Refresh bookings data before navigating
        context.read<UserBookingsProvider>().loadUserBookings(forceRefresh: true);
        // /bookings is a top-level route, use push
        context.push('/bookings');
        break;
      case 'message':
        // /chat is inside StatefulShellRoute - must use go() to switch branch
        context.go('/chat');
        break;
      case 'property':
        // Navigate to property if referenceId exists
        final propertyId = _extractPropertyId(notification);
        if (propertyId != null) {
          // /property/:id is a top-level route, use push
          context.push('/property/$propertyId');
        }
        break;
      case 'payment':
        // Refresh invoices data before navigating
        final currentUserProvider = context.read<CurrentUserProvider>();
        context.read<InvoicesProvider>().loadPending(currentUserProvider);
        // /profile/invoices is inside StatefulShellRoute - must use go() to switch branch
        context.go('/profile/invoices');
        break;
      case 'maintenance':
        // /profile/maintenance is inside StatefulShellRoute - must use go() to switch branch
        context.go('/profile/maintenance');
        break;
      case 'review':
      case 'system':
      default:
        // Show notification details in a dialog
        _showNotificationDetailDialog(context, notification);
        break;
    }
  }

  /// Extract property ID from notification actionUrl
  int? _extractPropertyId(AppNotification notification) {
    final actionUrl = notification.actionUrl;
    if (actionUrl == null) return null;
    
    // Try to extract property ID from URL (e.g., "/property/123")
    if (actionUrl.contains('/property/')) {
      final match = RegExp(r'/property/(\d+)').firstMatch(actionUrl);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '');
      }
    }
    // Try to parse the entire actionUrl as a number (might just be the ID)
    return int.tryParse(actionUrl);
  }

  void _showNotificationDetailDialog(BuildContext context, AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title ?? 'Notification'),
        content: Text(notification.message ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
