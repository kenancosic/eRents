import 'package:e_rents_mobile/core/models/property_detail.dart';
import 'package:e_rents_mobile/features/auth/screens/login_screen.dart';
import 'package:e_rents_mobile/features/auth/screens/signup_screen.dart';
import 'package:e_rents_mobile/features/explore/explore_screen.dart';
import 'package:e_rents_mobile/features/home/home_screen.dart';
import 'package:e_rents_mobile/features/chat/screens/contacts_screen.dart';
import 'package:e_rents_mobile/features/chat/screens/conversation_screen.dart';
import 'package:e_rents_mobile/features/profile/screens/personal_details_screen.dart';
import 'package:e_rents_mobile/features/profile/screens/booking_history_screen.dart';
import 'package:e_rents_mobile/features/profile/screens/profile_screen.dart';
import 'package:e_rents_mobile/features/profile/screens/payment_screen.dart';
import 'package:e_rents_mobile/features/profile/screens/change_password_screen.dart';
import 'package:e_rents_mobile/features/property_detail/screens/property_details_screen.dart';
import 'package:e_rents_mobile/features/property_detail/utils/view_context.dart';
import 'package:e_rents_mobile/features/property_detail/screens/report_issue_screen.dart';
import 'package:e_rents_mobile/features/property_detail/screens/manage_booking_screen.dart';
import 'package:e_rents_mobile/features/users/screens/public_user_screen.dart';
import 'package:e_rents_mobile/features/saved/saved_screen.dart';
import 'package:e_rents_mobile/core/widgets/filter_screen.dart';
import 'package:e_rents_mobile/features/checkout/checkout_screen.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/features/auth/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_mobile/features/auth/screens/forgot_password_screen.dart';
import 'package:e_rents_mobile/features/auth/screens/password_reset_confirmation_screen.dart';
import 'package:e_rents_mobile/features/auth/screens/verification_screen.dart';
import 'package:e_rents_mobile/features/auth/screens/create_password_screen.dart';
import 'package:e_rents_mobile/features/faq/screens/faq_screen.dart';
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
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final path = state.uri.path;
        final isAuthRoute = path == '/login' ||
            path == '/signup' ||
            path == '/forgot_password' ||
            path == '/verification' ||
            path == '/create-password' ||
            path == '/password_reset_confirmation';

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
                  builder: (context, state) => const ContactsScreen(),
                  routes: <RouteBase>[
                    GoRoute(
                      path: ':contactId',
                      name: 'conversation',
                      builder: (context, state) {
                        final contactId = int.parse(state.pathParameters['contactId']!);
                        final extras = state.extra as Map<String, dynamic>?;
                        final contactName = extras?['name'] as String? ?? 'Conversation';
                        return ConversationScreen(contactId: contactId, contactName: contactName);
                      },
                    ),
                  ],
              ),
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
                        path: 'change-password',
                        name: 'change_password',
                        builder: (context, state) => const ChangePasswordScreen()),
                    GoRoute(
                        path: 'payment',
                        name: 'profile_payment',
                        builder: (context, state) => const PaymentScreen()),
                    GoRoute(
                        path: 'booking-history',
                        name: 'profile_booking_history',
                        builder: (context, state) => const BookingHistoryScreen()),
                  ]),
              GoRoute(
                  path: '/faq', // FAQ as part of the profile shell
                  name: 'faq',
                  builder: (context, state) => const FAQScreen()),
            ],
          ),
        ],
      ),
      // Public user profile
      GoRoute(
        path: '/user/:id',
        name: 'public_user',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final extras = state.extra as Map<String, dynamic>?;
          final displayName = extras?['displayName'] as String?;
          return PublicUserScreen(userId: id, displayName: displayName);
        },
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
      // NEW: Verification screen for password reset
      GoRoute(
        path: '/verification',
        name: 'verification',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerificationScreen(email: email);
        },
      ),
      // NEW: Create password screen
      GoRoute(
        path: '/create-password',
        name: 'create_password',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final code = state.uri.queryParameters['code'] ?? '';
          return CreatePasswordScreen(email: email, code: code);
        },
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
        path: '/bookings',
        name: 'bookings',
        builder: (BuildContext context, GoRouterState state) {
          final tabStr = state.uri.queryParameters['tab'];
          final initialTab = int.tryParse(tabStr ?? '') ?? 0;
          return BookingHistoryScreen(initialTabIndex: initialTab);
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
          final property = arguments['property'] as PropertyDetail?;
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
