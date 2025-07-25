import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:e_rents_desktop/widgets/custom_avatar.dart';

class AppNavigationBar extends StatefulWidget {
  final String currentPath;

  const AppNavigationBar({super.key, required this.currentPath});

  @override
  State<AppNavigationBar> createState() => _AppNavigationBarState();
}

class _AppNavigationBarState extends State<AppNavigationBar> {
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
      label: 'Statistics',
      icon: Icons.bar_chart_rounded,
      path: '/statistics',
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
                // Header with logo
                _buildHeader(context),

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
            Icon(
              item.icon,
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
              size: 20,
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
        onTap: () => context.go('/login'),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () => context.go('/'),
        child: SizedBox(
          width: double.infinity,
          height: 30,
          child: SvgPicture.asset(
            'assets/images/logo.svg',
            fit: BoxFit.scaleDown,
            placeholderBuilder:
                (BuildContext context) =>
                    const Center(child: Icon(Icons.home, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context) {
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
              imageUrl: 'assets/images/user-image.png',
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
