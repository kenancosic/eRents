import 'package:e_rents_mobile/pages/scaffold_with_navbar.dart';
import 'package:e_rents_mobile/routes/error_page_builder.dart';
import 'package:e_rents_mobile/screens/home_screen.dart';
import 'package:e_rents_mobile/screens/login_screen.dart';
import 'package:e_rents_mobile/screens/profile_screen.dart';
import 'package:e_rents_mobile/screens/signup_screen.dart'; // Import SignUpScreen
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatiorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

class MyRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    navigatorKey: _rootNavigatiorKey,
    errorBuilder: errorPageBuilder,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register', // Define the route for SignUpScreen
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
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
