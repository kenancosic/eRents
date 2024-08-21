import 'package:e_rents_mobile/screens/auth/login_screen.dart';
import 'package:e_rents_mobile/screens/auth/signup_screen.dart';
import 'package:e_rents_mobile/screens/booking/booking_list_screen.dart';
import 'package:e_rents_mobile/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class AppRouter {
  // Define the GoRouter instance
  final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>  HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) =>  LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) =>  SignupScreen(),
      ),
      GoRoute(
        path: '/bookings',
        builder: (context, state) => const BookingListScreen(),
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
