import 'package:e_rents_mobile/feature/auth/screens/login_screen.dart';
import 'package:e_rents_mobile/feature/auth/screens/signup_screen.dart';
import 'package:e_rents_mobile/feature/chat/chat_room_screen.dart';
import 'package:e_rents_mobile/feature/chat/chat_screen.dart';
import 'package:e_rents_mobile/feature/explore/explore_screen.dart';
import 'package:e_rents_mobile/feature/home/home_screen.dart';
import 'package:e_rents_mobile/feature/profile/payment_screen.dart';
import 'package:e_rents_mobile/feature/profile/personal_details_screen.dart';
import 'package:e_rents_mobile/feature/profile/profile_screen.dart';
import 'package:e_rents_mobile/feature/property_detail/property_details_screen.dart';
import 'package:e_rents_mobile/feature/saved/saved_screen.dart';
import 'package:e_rents_mobile/core/widgets/filter_screen.dart';
import 'package:e_rents_mobile/feature/checkout/checkout_screen.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_mobile/feature/auth/screens/forgot_password_screen.dart'; // Import ForgotPasswordScreen
import 'package:e_rents_mobile/feature/auth/screens/password_reset_confirmation_screen.dart'; // Import PasswordResetConfirmationScreen

class AppRouter {
  // Define the GoRouter instance
  final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => HomeScreen(),
      ),
      GoRoute(
        path: '/property/:id',
        name: 'property_detail',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return PropertyDetailScreen(propertyId: id);
        },
      ),
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
      GoRoute(
          path: '/explore',
          name: 'explore',
          builder: (context, state) => const ExploreScreen()),
      GoRoute(
        path: '/chatRoom',
        builder: (context, state) => ChatRoomScreen(),
      ),
      GoRoute(
        path: '/saved',
        name: 'saved',
        builder: (context, state) => const SavedScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final chatDetails = state.extra
              as Map<String, dynamic>; // Pass data to the ChatScreen
          return ChatScreen(
            userName: chatDetails['name'],
            userImage: chatDetails['imageUrl'],
          );
        },
      ),
      GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen()),
      GoRoute(
          path: '/profile/details',
          name: 'personal_details',
          builder: (context, state) => const PersonalDetailsScreen()),
      GoRoute(
          path: '/profile/payment',
          name: 'payment_details',
          builder: (context, state) => const PaymentScreen()),
      GoRoute(
        path: '/filter',
        name: 'filter',
        builder: (BuildContext context, GoRouterState state) {
          final arguments = state.extra as Map<String, dynamic>?;
          final onApplyFiltersCallback =
              arguments?['onApplyFilters'] as Function(Map<String, dynamic>)? ??
                  (filters) {
                    print(
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
      GoRoute(
          path: '/faq',
          name: 'faq',
          builder: (context, state) => const Scaffold(
                body: Center(child: Text('FAQ Screen - Coming Soon')),
              )),
      GoRoute(
          path: '/profile/settings',
          name: 'settings',
          builder: (context, state) => const Scaffold(
                body: Center(child: Text('Settings Screen - Coming Soon')),
              )),
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
