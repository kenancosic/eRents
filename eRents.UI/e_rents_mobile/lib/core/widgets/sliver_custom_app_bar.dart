import 'dart:ui';
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
  final bool useGradientOverlay;
  final List<Color>? gradientColors;
  final bool useFrostedGlass;
  final double blurAmount;

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
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    this.customBorderRadius,
    this.customToolbarHeight,
    this.showTitle = true,
    this.showBackButton = false,
    this.titleText,
    this.useGradientOverlay = true,
    this.gradientColors,
    this.useFrostedGlass = true,
    this.blurAmount = 10.0,
  });

  bool get _hasBottomRow => locationWidget != null || notification != null;

  static const double _defaultToolbarHeight = 80.0;
  static const double _minimumBottomRowHeight = 50.0;

  // Default gradient colors used throughout the app
  List<Color> get _defaultGradientColors => const [
        Color(0xFF7065F0),
        Color(0xFF5D54C2),
      ];

  // Get the gradient to use based on provided colors or defaults
  LinearGradient get _appGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors ?? _defaultGradientColors,
      );

  Widget _buildBackground() {
    if (backgroundImagePath != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            backgroundImagePath!,
            fit: BoxFit.cover,
          ),
          // Apply a gradient overlay on top of the image for consistency
          if (useGradientOverlay)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
        ],
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          gradient: _appGradient,
        ),
      );
    }
  }

  Widget _buildFlexibleSpace(BuildContext context) {
    return FlexibleSpaceBar(
      background: ClipRRect(
        borderRadius: customBorderRadius ?? BorderRadius.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background (image or gradient)
            _buildBackground(),

            // Bottom row with location and notification
            if (_hasBottomRow)
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
                color: useFrostedGlass
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: useFrostedGlass
                    ? BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: blurAmount / 2,
                          sigmaY: blurAmount / 2,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: gradientColors?[0] ?? const Color(0xFF7065F0),
                          size: 22,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
              ),
            ),
          if (showBackButton && showTitle) const SizedBox(width: 16),
          if (showTitle)
            Expanded(
              child: Text(
                titleText ?? 'Title',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color:
                      useFrostedGlass ? Colors.white : const Color(0xFF1F2937),
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
    Widget content = Column(
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

    if (useFrostedGlass) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: content,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: content,
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
