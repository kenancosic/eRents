import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:e_rents_desktop/widgets/custom_avatar.dart';

class AppNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  final String currentPath;
  final double breakpointWidth;

  const AppNavigationBar({
    super.key,
    required this.currentPath,
    this.breakpointWidth = 1200,
  });

  @override
  Size get preferredSize => const Size.fromHeight(90);

  static const List<NavigationItem> navigationItems = [
    NavigationItem(label: 'Home', icon: Icons.home, path: '/'),
    NavigationItem(label: 'Chat', icon: Icons.chat, path: '/chat'),
    NavigationItem(
      label: 'Properties',
      icon: Icons.apartment,
      path: '/properties',
    ),
    NavigationItem(
      label: 'Statistics',
      icon: Icons.bar_chart,
      path: '/statistics',
    ),
    NavigationItem(label: 'Logout', icon: Icons.logout, path: '/login'),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > breakpointWidth;

    return CustomAppBar(
      height: isWideScreen ? 90 : 0,
      child: Container(
        height: isWideScreen ? 90 : double.infinity,
        width: isWideScreen ? double.infinity : 250,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 3,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child:
            isWideScreen
                ? _buildHorizontalNav(context)
                : _buildVerticalNav(context),
      ),
    );
  }

  Widget _buildHorizontalNav(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLogo(context),
                const SizedBox(width: 30),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _buildNavItems(context, false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          _buildProfile(context),
        ],
      ),
    );
  }

  Widget _buildVerticalNav(BuildContext context) {
    return Column(
      children: [
        Padding(padding: const EdgeInsets.all(20), child: _buildLogo(context)),
        const Divider(),
        Expanded(child: Column(children: _buildNavItems(context, true))),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(20),
          child: _buildProfile(context),
        ),
      ],
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.apartment,
          color: Theme.of(context).colorScheme.primary,
          size: 32,
        ),
        const SizedBox(width: 8),
        Text(
          'eRents',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildNavItems(BuildContext context, bool isVertical) {
    return navigationItems.map((item) {
      final isSelected = currentPath == item.path;
      return Padding(
        padding:
            isVertical
                ? const EdgeInsets.symmetric(vertical: 12, horizontal: 20)
                : const EdgeInsets.symmetric(horizontal: 8),
        child: GestureDetector(
          onTap: () => context.go(item.path),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: 22,
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 10),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildProfile(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomAvatar(
          imageUrl: 'assets/images/user-image.png',
          size: 40,
          borderWidth: currentPath == '/profile' ? 3 : 0,
          onTap: () => context.go('/profile'),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            'John Doe',
            style: TextStyle(
              fontSize: 15,
              color:
                  currentPath == '/profile'
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

class CustomAppBar extends PreferredSize {
  final Widget child;
  final double height;

  CustomAppBar({super.key, required this.height, required this.child})
    : super(child: child, preferredSize: Size.fromHeight(height));
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
