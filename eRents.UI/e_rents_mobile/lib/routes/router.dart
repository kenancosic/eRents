import 'package:e_rents_mobile/feature/auth/screens/login_screen.dart';
import 'package:e_rents_mobile/feature/auth/screens/signup_screen.dart';
import 'package:e_rents_mobile/feature/home/home_screen.dart';
import 'package:e_rents_mobile/feature/property_detail/property_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_mobile/feature/auth/screens/forgot_password_screen.dart';  // Import ForgotPasswordScreen
import 'package:e_rents_mobile/feature/auth/screens/password_reset_confirmation_screen.dart';  // Import PasswordResetConfirmationScreen

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
        builder: (context, state) => SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot_password',
        name: 'forgot_password',
        builder: (context, state) => ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/password_reset_confirmation',
        name: 'password_reset_confirmation',
        builder: (context, state) => PasswordResetConfirmationScreen(),
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
