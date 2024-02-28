import 'dart:js';

import 'package:e_rents_mobile/pages/templates/ScaffoldWithNavBar.dart';
import 'package:e_rents_mobile/screens/login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatiorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

class MyRouter {
  static final GoRouter router = new GoRouter(
      initialLocation: '/login',
      navigatorKey: _rootNavigatiorKey,
      errorBuilder: _errorPageBuilder,
      routes: [
        ShellRoute(
            navigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state, child) {
              return CupertinoPage(
                  key: state.pageKey,
                  child: ScaffoldWithNavBar(
                    location: state.location,
                    child: child,
                  ));
            })
      ]);
}
