import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/features/notifications/providers/notification_provider.dart';
import 'package:e_rents_desktop/features/notifications/widgets/notification_item.dart';
import 'package:e_rents_desktop/theme/theme.dart';

/// Main notifications screen for desktop app
/// 
/// Features:
/// - Filter by notification type
/// - Mark all as read
/// - Infinite scroll pagination
/// - Empty state
/// - Navigation to related content on tap
/// - Desktop-optimized layout with filters panel
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'all';

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
      context.read<NotificationProvider>().refresh();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationProvider>().loadMore();
    }
  }

  List<AppNotification> _filterNotifications(List<AppNotification> notifications) {
    if (_selectedFilter == 'all') return notifications;
    if (_selectedFilter == 'unread') {
      return notifications.where((n) => !n.isRead).toList();
    }
    return notifications.where((n) => n.type?.toLowerCase() == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          final filteredNotifications = _filterNotifications(provider.notifications);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with filters
              _buildHeader(context, provider),
              
              // Content
              Expanded(
                child: _buildContent(context, provider, filteredNotifications),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, NotificationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Icon(
                Icons.notifications_rounded,
                color: primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Spacer(),
              // Unread count badge
              if (provider.unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${provider.unreadCount} unread',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              const SizedBox(width: 16),
              // Mark all as read button
              if (provider.unreadCount > 0)
                OutlinedButton.icon(
                  onPressed: () => _markAllAsRead(context),
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Mark all as read'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              const SizedBox(width: 12),
              // Refresh button
              IconButton(
                onPressed: _loadInitialData,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Filter chips
          _buildFilterChips(provider),
        ],
      ),
    );
  }

  Widget _buildFilterChips(NotificationProvider provider) {
    final filters = [
      ('all', 'All', Icons.inbox_rounded),
      ('unread', 'Unread', Icons.mark_email_unread_rounded),
      ('booking', 'Booking', Icons.calendar_today_rounded),
      ('payment', 'Payment', Icons.payment_rounded),
      ('maintenance', 'Maintenance', Icons.build_rounded),
      ('review', 'Review', Icons.star_rounded),
      ('message', 'Message', Icons.chat_bubble_rounded),
      ('system', 'System', Icons.settings_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = filter.$1),
              avatar: Icon(
                filter.$3,
                size: 16,
                color: isSelected ? Colors.white : textSecondaryColor,
              ),
              label: Text(filter.$2),
              selectedColor: primaryColor,
              backgroundColor: Colors.grey.shade100,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : textPrimaryColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    NotificationProvider provider,
    List<AppNotification> notifications,
  ) {
    // Loading state
    if (provider.isLoading && provider.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (provider.hasError && provider.isEmpty) {
      return _buildErrorState(context, provider);
    }

    // Empty state
    if (notifications.isEmpty) {
      return _buildEmptyState(context);
    }

    // Content
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: notifications.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator at bottom
        if (index >= notifications.length) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final notification = notifications[index];
        return NotificationItem(
          notification: notification,
          onTap: () => _handleNotificationTap(context, notification),
          onMarkAsRead: () => provider.markAsRead(notification.notificationId),
          onDelete: () => _deleteNotification(context, notification),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 50,
              color: textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedFilter == 'all' 
                ? 'No notifications yet' 
                : 'No ${_selectedFilter} notifications',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: textPrimaryColor,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedFilter == 'all'
                ? 'When you receive notifications about bookings,\npayments, or messages, they\'ll appear here.'
                : 'Try selecting a different filter to see more notifications.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textSecondaryColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          if (_selectedFilter != 'all')
            TextButton.icon(
              onPressed: () => setState(() => _selectedFilter = 'all'),
              icon: const Icon(Icons.filter_list_off),
              label: const Text('Clear filter'),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, NotificationProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: textPrimaryColor,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            provider.error != null && provider.error!.isNotEmpty 
                ? provider.error! 
                : 'Unable to load notifications',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textSecondaryColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadInitialData,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllAsRead(BuildContext context) async {
    final provider = context.read<NotificationProvider>();
    final success = await provider.markAllAsRead();
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteNotification(BuildContext context, AppNotification notification) async {
    final provider = context.read<NotificationProvider>();
    final success = await provider.deleteNotification(notification.notificationId);
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
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
        context.go('/rents');
        break;
      case 'message':
        context.go('/chat');
        break;
      case 'maintenance':
        context.go('/maintenance');
        break;
      case 'property':
        context.go('/properties');
        break;
      case 'payment':
      case 'review':
      case 'system':
      default:
        _showNotificationDetailDialog(context, notification);
        break;
    }
  }

  void _showNotificationDetailDialog(BuildContext context, AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getNotificationIcon(notification.type),
              color: primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(notification.title ?? 'Notification'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message ?? '',
              style: TextStyle(
                color: textPrimaryColor,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Received: ${_formatFullDate(notification.createdAt)}',
              style: TextStyle(
                color: textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
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

  String _formatFullDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
