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
  bool _isExpanded = true;

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
    NavigationItem(label: 'Logout', icon: Icons.logout_rounded, path: '/login'),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isExpanded ? 250 : 70,
      child: Drawer(
        elevation: 2,
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(children: _buildNavItems(context)),
              ),
            ),
            const Divider(),
            _buildProfile(context),
            const SizedBox(height: 8),
            _buildExpandButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(
        horizontal: _isExpanded ? 16 : 8,
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment:
            _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: GestureDetector(
              onTap: () => context.go('/'),
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                firstChild: SizedBox(
                  width: _isExpanded ? 180 : 40,
                  height: 40,
                  child: SvgPicture.asset(
                    'assets/images/Logo.svg',
                    fit: BoxFit.contain,
                    placeholderBuilder:
                        (BuildContext context) => Container(
                          color: Colors.grey.withOpacity(0.3),
                          child: const Center(child: Text('Logo')),
                        ),
                  ),
                ),
                secondChild: SizedBox(
                  width: 40,
                  height: 40,
                  child: SvgPicture.asset(
                    'assets/images/house-icon.svg',
                    fit: BoxFit.contain,
                    placeholderBuilder:
                        (BuildContext context) => Container(
                          color: Colors.grey.withOpacity(0.3),
                          child: const Icon(Icons.home),
                        ),
                  ),
                ),
                crossFadeState:
                    _isExpanded
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                alignment: Alignment.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNavItems(BuildContext context) {
    return navigationItems.map((item) {
      final isSelected =
          widget.currentPath == item.path ||
          (item.subItems != null &&
              item.subItems!.any(
                (subItem) => widget.currentPath == subItem.path,
              ));

      if (item.subItems != null && item.subItems!.isNotEmpty) {
        return _buildExpandableNavItem(context, item, isSelected);
      } else {
        return _buildNavItem(context, item, isSelected);
      }
    }).toList();
  }

  Widget _buildExpandableNavItem(
    BuildContext context,
    NavigationItem item,
    bool isSelected,
  ) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        listTileTheme: ListTileTheme.of(
          context,
        ).copyWith(dense: true, horizontalTitleGap: 0, minLeadingWidth: 40),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(
          horizontal: _isExpanded ? 16 : 8,
          vertical: 0,
        ),
        leading: Icon(
          item.icon,
          size: 22,
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        title:
            _isExpanded
                ? Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                )
                : const SizedBox.shrink(),
        trailing:
            _isExpanded
                ? Icon(
                  Icons.expand_more,
                  size: 20,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                )
                : null,
        initiallyExpanded: isSelected,
        maintainState: true,
        children:
            item.subItems!.map((subItem) {
              final isSubItemSelected = widget.currentPath == subItem.path;
              return _buildNavItem(
                context,
                subItem,
                isSubItemSelected,
                isSubItem: true,
              );
            }).toList(),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    NavigationItem item,
    bool isSelected, {
    bool isSubItem = false,
  }) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.only(
        left: isSubItem ? (_isExpanded ? 56 : 8) : (_isExpanded ? 16 : 8),
        right: _isExpanded ? 16 : 8,
        top: 0,
        bottom: 0,
      ),
      minLeadingWidth: 24,
      horizontalTitleGap: 8,
      leading: Container(
        width: 24,
        alignment: Alignment.center,
        child: Icon(
          item.icon,
          size: 20,
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      title:
          _isExpanded
              ? Text(
                item.label,
                style: TextStyle(
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              )
              : null,
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      onTap: () => context.go(item.path),
    );
  }

  Widget _buildProfile(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: _isExpanded ? 16 : 0,
        vertical: 8,
      ),
      leading:
          _isExpanded
              ? CustomAvatar(
                imageUrl: 'assets/images/user-image.png',
                size: 32,
                borderWidth: widget.currentPath == '/profile' ? 2 : 0,
              )
              : null,
      title:
          _isExpanded
              ? Text(
                'John Doe',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      widget.currentPath == '/profile'
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                ),
                overflow: TextOverflow.ellipsis,
              )
              : null,
      trailing:
          !_isExpanded
              ? Padding(
                padding: const EdgeInsets.only(right: 19),
                child: CustomAvatar(
                  imageUrl: 'assets/images/user-image.png',
                  size: 32,
                  borderWidth: widget.currentPath == '/profile' ? 2 : 0,
                ),
              )
              : null,
      onTap: () => context.go('/profile'),
      selected: widget.currentPath == '/profile',
      selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
    );
  }

  Widget _buildExpandButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: IconButton(
        icon: Icon(_isExpanded ? Icons.chevron_left : Icons.chevron_right),
        onPressed: () {
          setState(() {
            _isExpanded = !_isExpanded;
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
