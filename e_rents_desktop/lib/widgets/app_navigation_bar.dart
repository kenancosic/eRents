import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/widgets/custom_avatar.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:e_rents_desktop/features/profile/providers/profile_provider.dart';
import 'package:e_rents_desktop/features/chat/providers/chat_provider.dart';

class AppNavigationBar extends StatefulWidget {
  final String currentPath;

  const AppNavigationBar({super.key, required this.currentPath});

  @override
  State<AppNavigationBar> createState() => _AppNavigationBarState();
}

class _AppNavigationBarState extends State<AppNavigationBar> {
  @override
  void initState() {
    super.initState();
    // Load profile and chat contacts on first display
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = context.read<ProfileProvider>();
      if (profileProvider.currentUser == null && !profileProvider.isLoading) {
        profileProvider.loadUserProfile();
      }
      // Load chat contacts to get unread count
      final chatProvider = context.read<ChatProvider>();
      if (chatProvider.contacts.isEmpty && !chatProvider.isLoading) {
        chatProvider.loadContacts();
      }
    });
  }

  static const List<NavigationItem> navigationItems = [
    NavigationItem(label: 'Home', icon: Icons.home_rounded, path: '/'),
    NavigationItem(label: 'Chat', icon: Icons.chat_rounded, path: '/chat'),
    NavigationItem(
      label: 'Properties',
      icon: Icons.apartment_rounded,
      path: '/properties',
    ),
    NavigationItem(
      label: 'Rentals',
      icon: Icons.home_work_rounded,
      path: '/rents',
    ),
    NavigationItem(
      label: 'Maintenance',
      icon: Icons.build_rounded,
      path: '/maintenance',
    ),
    NavigationItem(
      label: 'Reports',
      icon: Icons.summarize_rounded,
      path: '/reports',
    ),
    NavigationItem(
      label: 'Tenants',
      icon: Icons.person_rounded,
      path: '/tenants',
    ),
    NavigationItem(
      label: 'Notifications',
      icon: Icons.notifications_rounded,
      path: '/notifications',
    ),
  ];





  // Check if the current path is this item or a child path
  bool _isItemSelected(NavigationItem item) {
    if (widget.currentPath == item.path) {
      return true;
    }

    if (item.path != '/' && widget.currentPath.startsWith('${item.path}/')) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return _buildNavigationRail(context);
  }

  Widget _buildNavigationRail(BuildContext context) {
    final railWidth = 80.0;

    return Container(
      width: railWidth,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/polygon.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Dark overlay for better readability
          Positioned.fill(
            child: Container(color: Colors.black.withAlpha(102)),
          ),

          // Navigation Rail
          SizedBox(
            width: railWidth,
            height: double.infinity,
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Navigation items
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildNavigationItems(context),
                  ),
                ),

                // Profile and logout
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Divider(color: Colors.white.withValues(alpha: 0.2), thickness: 1),
                    _buildProfile(context),
                    _buildLogoutButton(context),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItems(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < navigationItems.length; i++)
          _buildNavigationItem(context, navigationItems[i], i),
      ],
    );
  }

  Widget _buildNavigationItem(
    BuildContext context,
    NavigationItem item,
    int index,
  ) {
    final bool isSelected = _isItemSelected(item);
    
    // Check for unread chat messages
    int? badgeCount;
    if (item.path == '/chat') {
      final chatProvider = context.watch<ChatProvider>();
      final unread = chatProvider.totalUnreadCount;
      if (unread > 0) badgeCount = unread;
    }

    return InkWell(
      onTap: () {
        context.go(item.path);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary.withAlpha(179)
                  : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
                if (badgeCount != null)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color:
                    isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () async {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.logout();
        },
        child: Column(
          children: [
            Icon(
              Icons.logout_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              'Logout',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final user = profileProvider.currentUser;
    
    // Build image URL from profile image ID if available
    String? imageUrl;
    if (user?.profileImageId != null) {
      imageUrl = '/Images/${user!.profileImageId}';
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: InkWell(
        onTap: () => context.go('/profile'),
        child: Container(
          decoration: BoxDecoration(
            color:
                widget.currentPath == '/profile'
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)
                    : Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          width: 40,
          child: Center(
            child: CustomAvatar(
              imageUrl: imageUrl ?? 'assets/images/user-image.png',
              size: 28,
              borderWidth: widget.currentPath == '/profile' ? 2 : 0,
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final String label;
  final IconData icon;
  final String path;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.path,
  });
}
