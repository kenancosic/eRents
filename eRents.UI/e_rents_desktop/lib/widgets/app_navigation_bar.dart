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
  bool _isExtended = true;
  int _selectedIndex = 0;

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
    NavigationItem(
      label: 'Tenants',
      icon: Icons.person_rounded,
      path: '/tenants',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Find the selected index based on the current path
    _updateSelectedIndex();
  }

  @override
  void didUpdateWidget(AppNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPath != widget.currentPath) {
      _updateSelectedIndex();
    }
  }

  void _updateSelectedIndex() {
    // Find main navigation item index
    for (int i = 0; i < navigationItems.length; i++) {
      final item = navigationItems[i];
      if (widget.currentPath == item.path) {
        setState(() {
          _selectedIndex = i;
        });
        return;
      }

      // Check sub-items
      if (item.subItems != null) {
        for (final subItem in item.subItems!) {
          if (widget.currentPath == subItem.path) {
            setState(() {
              _selectedIndex = i;
            });
            return;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Slightly reduce widths to prevent overflow
    final double railWidth = _isExtended ? 242 : 62;

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
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),

          // Main Navigation Rail with scroll capability
          ClipRect(
            child: SizedBox(
              width: railWidth,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: IntrinsicHeight(
                    child: NavigationRail(
                      labelType:
                          _isExtended
                              ? NavigationRailLabelType.none
                              : NavigationRailLabelType.all,
                      selectedIndex: _selectedIndex,
                      extended: _isExtended,
                      minWidth: 62,
                      minExtendedWidth: 242,
                      useIndicator: true,
                      indicatorColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.7),
                      backgroundColor: Colors.transparent,
                      unselectedIconTheme: IconThemeData(
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                      unselectedLabelTextStyle: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                      selectedIconTheme: const IconThemeData(
                        color: Colors.white,
                        size: 20,
                      ),
                      selectedLabelTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      groupAlignment: -0.85,
                      leading: _buildHeader(context),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 12),
                          Divider(
                            color: Colors.white.withOpacity(0.2),
                            thickness: 1,
                          ),
                          _buildProfile(context),
                          const SizedBox(height: 8),
                          _buildToggleButton(),
                        ],
                      ),
                      destinations: _buildDestinations(),
                      onDestinationSelected: (int index) {
                        setState(() {
                          _selectedIndex = index;
                        });

                        if (index < navigationItems.length) {
                          final item = navigationItems[index];
                          context.go(item.path);
                        } else {
                          // This is the logout button
                          context.go('/login');
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<NavigationRailDestination> _buildDestinations() {
    List<NavigationRailDestination> destinations = [];

    for (final item in navigationItems) {
      destinations.add(
        NavigationRailDestination(
          icon: Badge(
            isLabelVisible: item.subItems != null && item.subItems!.isNotEmpty,
            child: Icon(item.icon),
          ),
          selectedIcon: Badge(
            isLabelVisible: item.subItems != null && item.subItems!.isNotEmpty,
            backgroundColor: Colors.white,
            child: Icon(item.icon),
          ),
          label: Text(item.label),
          padding: const EdgeInsets.symmetric(vertical: 4),
        ),
      );
    }

    // Add logout as the last item
    destinations.add(
      const NavigationRailDestination(
        icon: Icon(Icons.logout_rounded),
        selectedIcon: Icon(Icons.logout_rounded),
        label: Text('Logout'),
        padding: EdgeInsets.symmetric(vertical: 4),
      ),
    );

    return destinations;
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () => context.go('/'),
        child: SizedBox(
          width: _isExtended ? 222 : 46,
          height: 56,
          child:
              _isExtended
                  ? SvgPicture.asset(
                    'assets/images/Logo.svg',
                    fit: BoxFit.contain,
                    placeholderBuilder:
                        (BuildContext context) => const Center(
                          child: Text(
                            'Logo',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                  )
                  : SvgPicture.asset(
                    'assets/images/house-icon.svg',
                    fit: BoxFit.contain,
                    placeholderBuilder:
                        (BuildContext context) => const Center(
                          child: Icon(Icons.home, color: Colors.white),
                        ),
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
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                    : Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          width: _isExtended ? 220 : 40, // Reduced to prevent overflow
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomAvatar(
                imageUrl: 'assets/images/user-image.png',
                size: 28, // Reduced size
                borderWidth: widget.currentPath == '/profile' ? 2 : 0,
              ),
              if (_isExtended) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'John Doe',
                    style: TextStyle(
                      fontSize: 12, // Reduced font size
                      color: Colors.white,
                      fontWeight:
                          widget.currentPath == '/profile'
                              ? FontWeight.bold
                              : FontWeight.normal,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          _isExtended ? Icons.chevron_left : Icons.chevron_right,
          color: Colors.white,
        ),
        onPressed: () {
          setState(() {
            _isExtended = !_isExtended;
          });
        },
      ),
    );
  }
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
