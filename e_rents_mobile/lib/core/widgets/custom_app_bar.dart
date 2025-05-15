import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
          const SizedBox(width: 8),
          Flexible(child: searchWidget!),
        ],
      );
    } else if (showAvatar && avatarWidget != null) {
      row1Content = avatarWidget;
    } else if (showSearch && searchWidget != null) {
      row1Content = searchWidget;
    } else if (title != null) {
      row1Content = Text(title!,
          style: Theme.of(context).appBarTheme.titleTextStyle ??
              const TextStyle(fontSize: 20, color: Colors.white));
    }

    PreferredSizeWidget? appBarBottom;
    double bottomWidgetHeight = 0;

    if (userLocationWidget != null) {
      bottomWidgetHeight = 50.0;
      appBarBottom = PreferredSize(
        preferredSize: Size.fromHeight(bottomWidgetHeight),
        child: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(
              left: NavigationToolbar.kMiddleSpacing,
              right: NavigationToolbar.kMiddleSpacing,
              top: 4.0,
              bottom: 8.0),
          child: userLocationWidget,
        ),
      );
    }

    return AppBar(
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
          : (showAvatar && avatarWidget != null && !showSearch)
              ? Padding(
                  padding: const EdgeInsets.only(
                      left: NavigationToolbar.kMiddleSpacing),
                  child: Center(child: avatarWidget),
                )
              : null,
      title: row1Content,
      titleSpacing: (showBackButton ||
              (showAvatar &&
                  avatarWidget != null &&
                  !showSearch &&
                  searchWidget == null))
          ? 0
          : NavigationToolbar.kMiddleSpacing,
      centerTitle: false,
      actions: actions,
      bottom: appBarBottom,
      toolbarHeight: kToolbarHeight,
    );
  }

  @override
  Size get preferredSize {
    double totalHeight = kToolbarHeight;
    if (userLocationWidget != null) {
      totalHeight += 50.0;
    }
    return Size.fromHeight(totalHeight);
  }
}
