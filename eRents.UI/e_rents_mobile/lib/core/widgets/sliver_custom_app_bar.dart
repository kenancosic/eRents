import 'package:flutter/material.dart';
import 'custom_search_bar2.dart';

class SliverCustomAppBar extends StatelessWidget {
  final Widget? avatar;
  final Widget? locationWidget;
  final Widget? notification;
  final ValueChanged<String>? onSearchChanged;
  final String? searchHintText;
  final bool showFilterIcon;
  final VoidCallback? onFilterIconPressed;
  final String? backgroundImagePath;
  final Color backgroundColor;
  final EdgeInsets contentPadding;
  final BorderRadius? customBorderRadius;
  final double? customToolbarHeight;

  const SliverCustomAppBar({
    super.key,
    this.avatar,
    this.locationWidget,
    this.notification,
    this.onSearchChanged,
    this.searchHintText,
    this.showFilterIcon = true,
    this.onFilterIconPressed,
    this.backgroundImagePath,
    this.backgroundColor = Colors.transparent,
    this.contentPadding =
        const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
    this.customBorderRadius,
    this.customToolbarHeight,
  });

  // Determine if we need the expanded bottom row
  bool get _hasBottomRow => locationWidget != null || notification != null;

  // Default measurements
 static const double _defaultToolbarHeight = 80.0;
  static const double _minimumBottomRowHeight = 50.0;
  static const BorderRadius _defaultBorderRadius = BorderRadius.only(
    bottomLeft: Radius.circular(20.0),
    bottomRight: Radius.circular(20.0),
  );

  Widget _buildFlexibleSpace(BuildContext context) {
    if (!_hasBottomRow) {
      return FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: customBorderRadius ?? _defaultBorderRadius,
          ),
        ),
      );
    }

    return FlexibleSpaceBar(
      background: ClipRRect(
        borderRadius: customBorderRadius ?? _defaultBorderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (backgroundImagePath != null)
              Image.asset(
                backgroundImagePath!,
                fit: BoxFit.cover,
              ),
            Container(
              color: Colors.black.withOpacity(0.5),
            ),
            // In SliverCustomAppBar, modify the container in _buildFlexibleSpace:
Positioned(
  bottom: 0,
  left: 0,
  right: 0,
  child: IntrinsicHeight(
    child: Container(
      padding: contentPadding,
      constraints: BoxConstraints(
        minHeight: _minimumBottomRowHeight,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(  // Changed from SizedBox with fixed width to Expanded
            child: locationWidget ?? const SizedBox(),
          ),
          if (notification != null)
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: notification!,
            ),
        ],
      ),
    ),
  ),
),
          ],
        ),
      ),
    );
  }

  // Builds the title row with search bar
  Widget _buildTitleRow(BuildContext context) {
    return Row(
      children: [
        if (avatar != null)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: avatar!,
          ),
        Flexible(
          flex: 1,
          child: CustomSearchBar(
            localData: const ['banana', 'mango'],
            key: key,
            searchHistory: const ['apple', 'mango'],
            onSearchChanged: onSearchChanged ?? (value) {},
            onFilterIconPressed: showFilterIcon ? onFilterIconPressed : null,
            hintText: searchHintText ?? 'Search',
            showFilterIcon: showFilterIcon,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double toolbarHeight = customToolbarHeight ?? _defaultToolbarHeight;

    // Calculate expanded height based on presence of bottom row
    final double expandedHeight =
        _hasBottomRow ? toolbarHeight + _minimumBottomRowHeight : toolbarHeight;

    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      toolbarHeight: toolbarHeight,
      expandedHeight: expandedHeight,
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: customBorderRadius ?? _defaultBorderRadius,
      ),
      clipBehavior: Clip.hardEdge,
      flexibleSpace: _buildFlexibleSpace(context),
      title: _buildTitleRow(context),
    );
  }
}
