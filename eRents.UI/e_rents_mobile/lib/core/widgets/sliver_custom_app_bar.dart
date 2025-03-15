import 'package:flutter/material.dart';
import 'custom_search_bar.dart';

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
  final bool showTitle;
  final bool showBackButton;
  final String? titleText;

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
    this.showTitle = true,
    this.showBackButton = false,
    this.titleText,
  });

  bool get _hasBottomRow => locationWidget != null || notification != null;

  static const double _defaultToolbarHeight = 80.0;
  static const double _minimumBottomRowHeight = 50.0;

  Widget _buildFlexibleSpace(BuildContext context) {
    if (!_hasBottomRow) {
      return FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
          ),
        ),
      );
    }

    return FlexibleSpaceBar(
      background: ClipRRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (backgroundImagePath != null)
              Image.asset(
                backgroundImagePath!,
                fit: BoxFit.cover,
              )
            else
              Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF7065F0),
                    Color(0xFF5D54C2),
                  ],
                )),
              ),
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
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
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

  Widget _buildTitleAndBackButtonRow(BuildContext context) {
    if (!showTitle && !showBackButton) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          if (showBackButton)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: Color(0xFF7065F0), size: 22),
                onPressed: () => Navigator.of(context).pop(),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),
            ),
          if (showBackButton && showTitle) const SizedBox(width: 16),
          if (showTitle)
            Expanded(
              child: Text(
                titleText ?? 'Title',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  fontFamily: 'Hind',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleAndBackButtonRow(context),
        Row(
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
                onFilterIconPressed:
                    showFilterIcon ? onFilterIconPressed : null,
                hintText: searchHintText ?? 'Search',
                showFilterIcon: showFilterIcon,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showTitleRow = showTitle || showBackButton;

    final double extraHeight = showTitleRow ? 48.0 : 0.0;
    final double toolbarHeight =
        (customToolbarHeight ?? _defaultToolbarHeight) + extraHeight;

    final double expandedHeight =
        _hasBottomRow ? toolbarHeight + _minimumBottomRowHeight : toolbarHeight;

    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      toolbarHeight: toolbarHeight,
      expandedHeight: expandedHeight,
      backgroundColor: backgroundColor,
      clipBehavior: Clip.hardEdge,
      flexibleSpace: _buildFlexibleSpace(context),
      title: _buildTitleRow(context),
    );
  }
}
