import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_mobile/core/utils/app_spacing.dart';
import 'package:e_rents_mobile/core/utils/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showAvatar;
  final Widget? avatarWidget;
  final bool showSearch;
  final Widget? searchWidget;
  final bool showBackButton;
  final String? title;
  final Widget? userLocationWidget;
  final VoidCallback? onBackButtonPressed;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    this.showAvatar = false,
    this.avatarWidget,
    this.showSearch = false,
    this.searchWidget,
    this.showBackButton = true,
    this.title,
    this.userLocationWidget,
    this.onBackButtonPressed,
    this.actions,
    this.bottom,
  })  : assert(showAvatar ? avatarWidget != null : true,
            'avatarWidget must be provided if showAvatar is true'),
        assert(showSearch ? searchWidget != null : true,
            'searchWidget must be provided if showSearch is true');

  @override
  Widget build(BuildContext context) {
    Widget? row1Content;

    if (showAvatar &&
        avatarWidget != null &&
        showSearch &&
        searchWidget != null) {
      row1Content = Row(
        children: [
          avatarWidget!,
          SizedBox(width: AppSpacing.sm),
          Flexible(child: searchWidget!),
        ],
      );
    } else if (showSearch && searchWidget != null) {
      row1Content = searchWidget;
    } else if (title != null) {
      row1Content = Text(title!,
          style: Theme.of(context).appBarTheme.titleTextStyle ??
              const TextStyle(fontSize: 20, color: Colors.white));
    } else if (userLocationWidget != null) {
      // Show location widget in title area when no title/search
      row1Content = userLocationWidget;
    }

    PreferredSizeWidget? appBarBottom;

    // Only use bottom if explicitly provided
    if (bottom != null) {
      appBarBottom = bottom;
    }

    return AppBar(
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.surfaceLight,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.overlayLight,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackButtonPressed ??
                  () {
                    if (context.canPop()) {
                      context.pop();
                    }
                  },
            )
          : (showAvatar && avatarWidget != null)
              ? Center(child: avatarWidget)
              : null,
      title: row1Content,
      titleSpacing: showBackButton ? 0 : NavigationToolbar.kMiddleSpacing,
      centerTitle: false,
      actions: actions,
      bottom: appBarBottom,
      toolbarHeight: kToolbarHeight,
    );
  }

  @override
  Size get preferredSize {
    double totalHeight = kToolbarHeight;
    if (bottom != null) {
      totalHeight += bottom!.preferredSize.height;
    }
    return Size.fromHeight(totalHeight);
  }
}
