import 'package:e_rents_mobile/models/user.dart';
import 'package:e_rents_mobile/pages/scaffold_with_navbar.dart';
import 'package:e_rents_mobile/providers/auth_provider.dart';
import 'package:e_rents_mobile/screens/home_screen.dart';
import 'package:e_rents_mobile/screens/login_screen.dart';
import 'package:e_rents_mobile/screens/signup_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'error_page_builder.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');
class MyRouter {
  static GoRouter router(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final goingToLogin = state.matchedLocation == '/login';

        // If the user is not authenticated, redirect them to the login page
        if (!isAuthenticated && !goingToLogin) {
          return '/login';
        }

        // If the user is authenticated and tries to go to the login page, redirect them to home
        if (isAuthenticated && goingToLogin) {
          return '/home';
        }

        return null; // No redirection
      },
      errorBuilder: errorPageBuilder,
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const SignUpScreen(),
        ),
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state, child) {
            return CupertinoPage(
              key: state.pageKey,
              child: ScaffoldWithNavBar(
                location: state.matchedLocation,
                child: child,
              ),
            );
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) {
                final user = state.extra as User?;
                if (user == null) {
                  throw Exception('User data is missing');
                }
                return HomeScreen(user: user);
              },
            ),
            // Other protected routes here
          ],
        ),
      ],
    );
  }
}