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
  Size get preferredSize => const Size.fromHeight(70);

  static const List<NavigationItem> navigationItems = [
    NavigationItem(label: 'Home', icon: Icons.home_rounded, path: '/'),
    NavigationItem(label: 'Chat', icon: Icons.chat_rounded, path: '/chat'),
    NavigationItem(
      label: 'Properties',
      icon: Icons.apartment_rounded,
      path: '/properties',
      subItems: [
        NavigationItem(
          label: 'Properties',
          icon: Icons.apartment_rounded,
          path: '/properties',
        ),
        NavigationItem(
          label: 'Maintenance',
          icon: Icons.build_rounded,
          path: '/maintenance',
        ),
      ],
    ),
    NavigationItem(
      label: 'Statistics',
      icon: Icons.bar_chart_rounded,
      path: '/statistics',
      subItems: [
        NavigationItem(
          label: 'Statistics',
          icon: Icons.bar_chart_rounded,
          path: '/statistics',
        ),
        NavigationItem(
          label: 'Reports',
          icon: Icons.description_rounded,
          path: '/reports',
        ),
      ],
    ),
    NavigationItem(label: 'Logout', icon: Icons.logout_rounded, path: '/login'),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 30),
                  child: _buildLogo(context),
                ),
                const VerticalDivider(),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.all(20), child: _buildLogo(context)),
        const Divider(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildNavItems(context, true),
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(20),
          child: _buildProfile(context),
        ),
      ],
    );
  }

  Widget _buildLogo(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/'),
      child: SizedBox(
        width: 100,
        height: 40,
        child: SvgPicture.asset('assets/images/Logo.svg'),
      ),
    );
  }

  List<Widget> _buildNavItems(BuildContext context, bool isVertical) {
    return navigationItems.map((item) {
      final isSelected =
          currentPath == item.path ||
          (item.subItems != null &&
              item.subItems!.any((subItem) => currentPath == subItem.path));

      if (item.subItems != null && item.subItems!.isNotEmpty) {
        return _buildDropdownItem(context, item, isVertical, isSelected);
      } else {
        return _buildSimpleNavItem(context, item, isVertical, isSelected);
      }
    }).toList();
  }

  Widget _buildDropdownItem(
    BuildContext context,
    NavigationItem item,
    bool isVertical,
    bool isSelected,
  ) {
    final selectedSubItem = item.subItems?.firstWhere(
      (subItem) => currentPath == subItem.path,
      orElse: () => item,
    );

    return Padding(
      padding:
          isVertical
              ? const EdgeInsets.symmetric(vertical: 12, horizontal: 20)
              : const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Main navigation item (clickable)
          GestureDetector(
            onTap: () => context.go(item.path),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selectedSubItem?.icon ?? item.icon,
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
                    selectedSubItem?.label ?? item.label,
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
          ),
          // Dropdown button for sub-items
          if (item.subItems != null && item.subItems!.isNotEmpty)
            PopupMenuButton<NavigationItem>(
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              itemBuilder:
                  (context) =>
                      item.subItems!.map((subItem) {
                        return PopupMenuItem<NavigationItem>(
                          value: subItem,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  subItem.icon,
                                  size: 20,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  subItem.label,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
              onSelected: (selectedItem) {
                context.go(selectedItem.path);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSimpleNavItem(
    BuildContext context,
    NavigationItem item,
    bool isVertical,
    bool isSelected,
  ) {
    return Padding(
      padding:
          isVertical
              ? const EdgeInsets.symmetric(vertical: 12, horizontal: 20)
              : const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () => context.go(item.path),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
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
      ),
    );
  }

  Widget _buildProfile(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/profile'),
      child: Row(
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
      ),
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
  final List<NavigationItem>? subItems;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.path,
    this.subItems,
  });
}
