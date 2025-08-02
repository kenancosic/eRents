import 'package:e_rents_mobile/feature/auth/screens/login_screen.dart';
import 'package:e_rents_mobile/feature/auth/screens/signup_screen.dart';
import 'package:e_rents_mobile/feature/explore/explore_screen.dart';
import 'package:e_rents_mobile/feature/home/home_screen.dart';
import 'package:e_rents_mobile/feature/home/screens/modern_home_screen.dart';
import 'package:e_rents_mobile/feature/chat/chat_screen.dart';
import 'package:e_rents_mobile/feature/profile/screens/personal_details_screen.dart';
import 'package:e_rents_mobile/feature/profile/screens/profile_screen.dart';
import 'package:e_rents_mobile/feature/profile/screens/tenant_preferences_screen.dart';
import 'package:e_rents_mobile/feature/property_detail/screens/property_details_screen.dart';
import 'package:e_rents_mobile/feature/property_detail/utils/view_context.dart';
import 'package:e_rents_mobile/feature/property_detail/screens/report_issue_screen.dart';
import 'package:e_rents_mobile/feature/property_detail/screens/manage_lease_screen.dart';
import 'package:e_rents_mobile/feature/property_detail/screens/manage_booking_screen.dart';
import 'package:e_rents_mobile/feature/saved/saved_screen.dart';
import 'package:e_rents_mobile/core/widgets/filter_screen.dart';
import 'package:e_rents_mobile/feature/checkout/checkout_screen.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/feature/auth/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_mobile/feature/auth/screens/forgot_password_screen.dart'; // Import ForgotPasswordScreen
import 'package:e_rents_mobile/feature/auth/screens/password_reset_confirmation_screen.dart'; // Import PasswordResetConfirmationScreen
import 'package:e_rents_mobile/core/widgets/custom_bottom_navigation_bar.dart';

// Navigator keys
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorAKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellA'); // Home
final _shellNavigatorBKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellB'); // Explore
final _shellNavigatorCKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellC'); // Chat
final _shellNavigatorDKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellD'); // Saved
final _shellNavigatorEKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellE'); // Profile

class AppRouter {
  final AuthProvider authProvider;
  late final GoRouter router;

  AppRouter(this.authProvider) {
    router = GoRouter(
      initialLocation: '/login',
      navigatorKey: _rootNavigatorKey,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isAuthRoute = state.uri.path == '/login' ||
            state.uri.path == '/signup' ||
            state.uri.path == '/forgot_password';

        if (isAuthenticated && isAuthRoute) {
          return '/';
        }

        if (!isAuthenticated && !isAuthRoute) {
          return '/login';
        }

        return null;
      },
      routes: [
        // StatefulShellRoute for tabbed navigation
        StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state,
            StatefulNavigationShell navigationShell) {
          // This is where you'd build your main scaffold with the CustomBottomNavigationBar
          // The navigationShell is used to display the correct page for the current tab
          // and to handle tab changes via the CustomBottomNavigationBar's onTap
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: CustomBottomNavigationBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) => navigationShell.goBranch(index),
            ),
          );
        },
        branches: <StatefulShellBranch>[
          // Branch A: Home
          StatefulShellBranch(
            navigatorKey: _shellNavigatorAKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => HomeScreen(),
                routes: [
                  // Property details can be accessed from Home or other tabs
                  // To keep it outside the shell but accessible, it's better as a top-level route
                  // If it should be *within* the home tab's stack, it stays here.
                  // For now, assuming it can be pushed over anything, let's move it top-level.
                ],
              ),
            ],
          ),
          // Branch B: Explore
          StatefulShellBranch(
            navigatorKey: _shellNavigatorBKey,
            routes: <RouteBase>[
              GoRoute(
                  path: '/explore',
                  name: 'explore',
                  builder: (context, state) => const ExploreScreen()),
            ],
          ),
          // Branch C: Chat
          StatefulShellBranch(
            navigatorKey: _shellNavigatorCKey,
            routes: <RouteBase>[
              GoRoute(
                  path: '/chat',
                  name: 'chat',
                  builder: (context, state) => const ChatScreen(
                        roomId: 'placeholder_room_id',
                        userName: 'Placeholder User',
                        userImage: 'assets/images/placeholder.png',
                      )),
            ],
          ),
          // Branch D: Saved
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDKey,
            routes: <RouteBase>[
              GoRoute(
                  path: '/saved',
                  name: 'saved',
                  builder: (context, state) => const SavedScreen()),
            ],
          ),
          // Branch E: Profile
          StatefulShellBranch(
            navigatorKey: _shellNavigatorEKey,
            routes: <RouteBase>[
              GoRoute(
                  path: '/profile',
                  name: 'profile',
                  builder: (context, state) => const ProfileScreen(),
                  routes: <RouteBase>[
                    GoRoute(
                        path: 'details',
                        name: 'personal_details', // name was personal_details
                        builder: (context, state) =>
                            const PersonalDetailsScreen()),
                    GoRoute(
                      path: 'accommodation-preferences',
                      name: 'accommodation_preferences',
                      builder: (context, state) =>
                          const TenantPreferencesScreen(),
                    ),
                  ]),
              GoRoute(
                  path: '/faq', // FAQ as part of the profile shell
                  name: 'faq',
                  builder: (context, state) => const Scaffold(
                        body: Center(child: Text('FAQ Screen - Coming Soon')),
                      )),
            ],
          ),
        ],
      ),

      // Top-level routes (not part of the bottom navigation bar)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot_password',
        name: 'forgot_password',
        builder: (context, state) => ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/password_reset_confirmation',
        name: 'password_reset_confirmation',
        builder: (context, state) => const PasswordResetConfirmationScreen(),
      ),
      // NEW: Modern home screen for testing repository architecture
      GoRoute(
        path: '/modern-home',
        name: 'modern_home',
        builder: (context, state) => const ModernHomeScreen(),
      ),
      GoRoute(
        path: '/property/:id', // Moved to be a top-level route
        name: 'property_detail',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final extras = state.extra as Map<String, dynamic>?;
          final viewContext =
              extras?['viewContext'] as ViewContext? ?? ViewContext.browsing;
          final bookingId = extras?['bookingId'] as int?;

          return PropertyDetailScreen(
            propertyId: id,
            viewContext: viewContext,
            bookingId: bookingId,
          );
        },
        routes: [
          GoRoute(
            path: 'report-issue',
            name: 'report_issue',
            builder: (context, state) {
              final propertyId = int.parse(state.pathParameters['id']!);
              final extras = state.extra as Map<String, dynamic>?;
              final bookingId = extras?['bookingId'] as int? ?? 0;

              return ReportIssueScreen(
                propertyId: propertyId,
                bookingId: bookingId,
              );
            },
          ),
          GoRoute(
            path: 'manage-lease',
            name: 'manage_lease',
            builder: (context, state) {
              final propertyId = int.parse(state.pathParameters['id']!);
              final extras = state.extra as Map<String, dynamic>?;
              final bookingId = extras?['bookingId'] as int? ?? 0;
              final booking = extras?['booking'] as Booking;

              return ManageLeaseScreen(
                propertyId: propertyId,
                bookingId: bookingId,
                booking: booking,
              );
            },
          ),
          GoRoute(
            path: 'manage-booking',
            name: 'manage_booking',
            builder: (context, state) {
              final propertyId = int.parse(state.pathParameters['id']!);
              final extras = state.extra as Map<String, dynamic>?;
              final bookingId = extras?['bookingId'] as int? ?? 0;
              final booking = extras?['booking'] as Booking;

              return ManageBookingScreen(
                propertyId: propertyId,
                bookingId: bookingId,
                booking: booking,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/filter',
        name: 'filter',
        builder: (BuildContext context, GoRouterState state) {
          final arguments = state.extra as Map<String, dynamic>?;
          final onApplyFiltersCallback =
              arguments?['onApplyFilters'] as Function(Map<String, dynamic>)? ??
                  (filters) {
                    debugPrint(
                        "Error: onApplyFilters not provided to /filter route. Filters: $filters");
                  };
          final initialFiltersData =
              arguments?['initialFilters'] as Map<String, dynamic>?;

          return FilterScreen(
            onApplyFilters: onApplyFiltersCallback,
            initialFilters: initialFiltersData,
          );
        },
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (BuildContext context, GoRouterState state) {
          final arguments = state.extra as Map<String, dynamic>?;
          if (arguments == null) {
            return const Text(
                'Error: Checkout arguments missing'); // Or an error screen
          }
          final property = arguments['property'] as Property?;
          final startDate = arguments['startDate'] as DateTime?;
          final endDate = arguments['endDate'] as DateTime?;
          final isDailyRental = arguments['isDailyRental'] as bool?;
          final totalPrice = arguments['totalPrice'] as double?;

          if (property == null ||
              startDate == null ||
              endDate == null ||
              isDailyRental == null ||
              totalPrice == null) {
            return const Text(
                'Error: Incomplete checkout arguments'); // Or an error screen
          }

          return CheckoutScreen(
            property: property,
            startDate: startDate,
            endDate: endDate,
            isDailyRental: isDailyRental,
            totalPrice: totalPrice,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: const Center(
        child: Text('ERROR: Route not found'),
      ),
      ),
    );
  }
}
