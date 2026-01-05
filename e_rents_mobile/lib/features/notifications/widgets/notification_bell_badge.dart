import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_mobile/features/notifications/providers/notification_provider.dart';
import 'package:e_rents_mobile/core/utils/app_colors.dart';

/// A notification bell icon with badge showing unread count
/// 
/// Usage:
/// ```dart
/// AppBar(
///   actions: [
///     NotificationBellBadge(),
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
  
  /// Whether to show the badge even when count is 0
  final bool alwaysShowBadge;

  const NotificationBellBadge({
    super.key,
    this.iconSize = 24,
    this.iconColor,
    this.badgeColor = AppColors.error,
    this.alwaysShowBadge = false,
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
      if (!mounted) return;
      context.read<NotificationProvider>().loadUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final count = provider.unreadCount;
        final showBadge = widget.alwaysShowBadge || count > 0;

        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_outlined,
                size: widget.iconSize,
                color: widget.iconColor ?? Theme.of(context).iconTheme.color,
              ),
              if (showBadge)
                Positioned(
                  right: -4,
                  top: -4,
                  child: _buildBadge(count),
                ),
            ],
          ),
          onPressed: () => context.push('/notifications'),
          tooltip: 'Notifications',
        );
      },
    );
  }

  Widget _buildBadge(int count) {
    final displayCount = count > 99 ? '99+' : count.toString();
    final width = count > 99 ? 24.0 : (count > 9 ? 20.0 : 16.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
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
          count > 0 ? displayCount : '',
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

/// Animated notification bell that shakes when new notifications arrive
class AnimatedNotificationBell extends StatefulWidget {
  final double iconSize;
  final Color? iconColor;
  final Color badgeColor;

  const AnimatedNotificationBell({
    super.key,
    this.iconSize = 24,
    this.iconColor,
    this.badgeColor = AppColors.error,
  });

  @override
  State<AnimatedNotificationBell> createState() => _AnimatedNotificationBellState();
}

class _AnimatedNotificationBellState extends State<AnimatedNotificationBell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 0.1)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_controller);
    
    // Load unread count
    Future.microtask(() {
      if (!mounted) return;
      context.read<NotificationProvider>().loadUnreadCount();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkForNewNotifications(int newCount) {
    if (newCount > _lastCount && _lastCount > 0) {
      _controller.forward(from: 0);
    }
    _lastCount = newCount;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        _checkForNewNotifications(provider.unreadCount);
        final count = provider.unreadCount;

        return AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _shakeAnimation.value * 0.5,
              child: child,
            );
          },
          child: IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  count > 0 ? Icons.notifications : Icons.notifications_outlined,
                  size: widget.iconSize,
                  color: widget.iconColor ?? Theme.of(context).iconTheme.color,
                ),
                if (count > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: _buildBadge(count),
                  ),
              ],
            ),
            onPressed: () => context.push('/notifications'),
            tooltip: 'Notifications',
          ),
        );
      },
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
