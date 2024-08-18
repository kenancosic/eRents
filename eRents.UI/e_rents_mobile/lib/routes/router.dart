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
      navigatorKey: _rootNavigatorKey,
      redirect: (context, state) {
        final isLoggedIn = authProvider.user != null;
        final isLoggingIn = state.matchedLocation == '/login';

        if (!isLoggedIn && !isLoggingIn) {
          return '/login';
        }

        if (isLoggedIn && (isLoggingIn || state.matchedLocation == '/register')) {
          return '/home';
        }

        return null;
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
                final user = authProvider.user!;
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

// import 'package:e_rents_mobile/models/user.dart';
// import 'package:e_rents_mobile/pages/scaffold_with_navbar.dart';
// import 'package:e_rents_mobile/routes/error_page_builder.dart';
// import 'package:e_rents_mobile/screens/forgot_password_screen.dart';
// import 'package:e_rents_mobile/screens/home_screen.dart';
// import 'package:e_rents_mobile/screens/property_list_screen.dart';
// import 'package:e_rents_mobile/screens/signup_screen.dart';
// import 'package:e_rents_mobile/screens/user_profile_screen.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:go_router/go_router.dart';
// import 'package:e_rents_mobile/screens/login_screen.dart';
// import 'package:e_rents_mobile/screens/booking_list_screen.dart';
// import 'package:e_rents_mobile/screens/notification_screen.dart'; // Import your screens

// final _rootNavigatiorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
// final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

// class MyRouter {
//   static final GoRouter router = GoRouter(
//     initialLocation: '/login',
//     navigatorKey: _rootNavigatiorKey,
//     errorBuilder: errorPageBuilder,
//     routes: [
//       GoRoute(
//         path: '/login',
//         builder: (context, state) => const LoginScreen(),
//       ),
//       GoRoute(
//         path: '/signup',
//         builder: (context, state) => const SignUpScreen(),
//       ),
//       GoRoute(
//         path: '/forgotpassword',
//         builder: (context, state) => const ForgotPasswordScreen(),
//       ),
//       ShellRoute(
//         navigatorKey: _shellNavigatorKey,
//         pageBuilder: (context, state, child) {
//           return CupertinoPage(
//             key: state.pageKey,
//             child: ScaffoldWithNavBar(
//               location: state.matchedLocation,
//               child: child,
//             ),
//           );
//         },
//         routes: [
//           GoRoute(
//             path: '/home',
//             builder: (context, state) {
//               final user = state.extra as User;
//               return HomeScreen(user: user);
//             },
//           ),
//           GoRoute(
//             path: '/profile',
//             builder: (context, state) => const UserProfileScreen(),
//           ),
//           GoRoute(
//             path: '/properties',
//             builder: (context, state) => const PropertyListScreen(),
//           ),
//           GoRoute(
//             path: '/bookings',
//             builder: (context, state) => const BookingListScreen(),
//           ),
//           GoRoute(
//             path: '/notifications',
//             builder: (context, state) => const NotificationsScreen(),
//           ),
//         ],
//       ),
//     ],
//   );
// }
