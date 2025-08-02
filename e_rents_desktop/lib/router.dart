import 'package:e_rents_desktop/features/auth/login_screen.dart';
import 'package:e_rents_desktop/features/auth/verification_screen.dart';
import 'package:e_rents_desktop/features/auth/create_password_screen.dart';
import 'package:e_rents_desktop/features/auth/signup_screen.dart';
import 'package:e_rents_desktop/features/auth/forgot_password_screen.dart';
import 'package:e_rents_desktop/features/home/home_screen.dart';
import 'package:e_rents_desktop/features/home/providers/home_provider.dart';
import 'package:e_rents_desktop/features/chat/providers/chat_provider.dart';
import 'package:e_rents_desktop/features/chat/chat_screen.dart';
import 'package:e_rents_desktop/features/properties/properties_screen.dart';
import 'package:e_rents_desktop/features/properties/property_details_screen.dart';
import 'package:e_rents_desktop/features/properties/property_form_screen.dart';
import 'package:e_rents_desktop/features/reports/providers/reports_provider.dart';
// Import screens from the screens subfolder with prefix
import 'package:e_rents_desktop/features/properties/screens/property_list_screen.dart' as property_screens;
import 'package:e_rents_desktop/features/properties/screens/property_detail_screen.dart' as property_screens;
import 'package:e_rents_desktop/features/properties/screens/property_form_screen.dart' as property_screens;
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:e_rents_desktop/features/reports/reports_screen.dart';
import 'package:e_rents_desktop/features/profile/profile_screen.dart';
import 'package:e_rents_desktop/features/profile/providers/profile_provider.dart';
import 'package:e_rents_desktop/features/rents/rents_screen.dart';

import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:e_rents_desktop/widgets/app_navigation_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'services/api_service.dart';
// ✅ NEW: Import base infrastructure and new providers
import 'features/properties/providers/properties_provider.dart';
import 'features/properties/widgets/property_images_grid.dart';



// Shell layout that includes the persistent navigation bar
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: Row(
        children: [
          AppNavigationBar(currentPath: location),
          Expanded(
            child: Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: child,
            ),
          ),
        ],
      ),
    );
  }
}

// Content wrapper that provides consistent styling for main app content
class ContentWrapper extends StatelessWidget {
  final String title;
  final Widget child;

  const ContentWrapper({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Title
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),

          // Main Content Area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25), // Corrected alpha value
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppRouter {
  final AuthProvider authProvider;
  late final GoRouter router;

  // ✅ NEW: Factory methods for creating screens with lazy persistent providers
  Widget _createHomeScreen(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeProvider(context.read<ApiService>()),
      child: const HomeScreen(),
    );
  }

  Widget _createPropertyDetailsScreen(BuildContext context, String propertyId) {
    return ChangeNotifierProvider(
      create: (_) =>
          PropertiesProvider(context.read<ApiService>())..getPropertyById(propertyId),
      child: PropertyDetailsScreen(propertyId: propertyId),
    );
  }

  Widget _createPropertiesScreen(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          PropertiesProvider(context.read<ApiService>())..getPagedProperties(),
      child: const PropertiesScreen(),
    );
  }


  Widget _createPropertyFormScreen(BuildContext context, String? propertyId) {
    return ChangeNotifierProvider(
      create: (_) => PropertiesProvider(context.read<ApiService>()),
      child: Builder(builder: (context) {
        if (propertyId == null) {
          // Add mode
          return const PropertyFormScreen(property: null);
        } else {
          // Edit mode
          // Fetch the property details using the provider
          context.read<PropertiesProvider>().getPropertyById(propertyId);
          return Consumer<PropertiesProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (provider.error != null) {
                return Center(child: Text('Error: ${provider.error}'));
              }
              return PropertyFormScreen(property: provider.selectedProperty);
            },
          );
        }
      }),
    );
  }




    Widget _createChatScreen(BuildContext context, {String? contactId}) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(context.read<ApiService>())..loadContacts(),
      child: ChatScreen(contactId: contactId),
    );
  }


  Widget _createReportsScreen(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportsProvider(context.read<ApiService>())..fetchCurrentReports(),
      child: const ReportsScreen(),
    );
  }

  Widget _createProfileScreen(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileProvider(context.read<ApiService>())..loadUserProfile(),
      child: const ProfileScreen(),
    );
  }

  Widget _createRentsTableScreen() {
    return const RentsScreen();
  }

  Widget _createImageCarouselScreen(List<int> images, int initialIndex) {
    return ImageCarouselDialog(
      images: images,
      initialIndex: initialIndex,
    );
  }


  AppRouter(this.authProvider) {
    router = GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (context, state) async {
        final isAuthenticated = authProvider.isAuthenticated;

      // Development mode check
      final bool isDevelopmentMode =
          !bool.fromEnvironment('dart.vm.product') ||
          Platform.environment.containsKey('FLUTTER_DEV_MODE');

      if (isDevelopmentMode && isAuthenticated) {
        if (state.uri.path == '/login') {
          return '/';
        }
        return null;
      }

      final isAuthRoute = state.uri.path == '/login' ||
          state.uri.path == '/signup' ||
          state.uri.path == '/forgot-password';

      // If the user is authenticated and trying to access an auth route, redirect to home
      if (isAuthenticated && isAuthRoute) {
        return '/';
      }

      // If the user is not authenticated and not on an auth route, redirect to login
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      // Otherwise, allow navigation
      return null;
    },
    routes: [
      // Auth routes (no shell - they use their own layout)
      GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/verification',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerificationScreen(email: email);
        }
      ),
      GoRoute(
        path: '/create-password',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final code = state.uri.queryParameters['code'] ?? '';
          return CreatePasswordScreen(email: email, code: code);
        }
      ),

      // Main app shell with persistent navigation
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // Main routes
          GoRoute(
            path: '/',
            builder:
                (context, state) => ContentWrapper(
                  title: 'Landlord Dashboard',
                  child: _createHomeScreen(context),
                ),
          ),
          GoRoute(
            path: '/properties',
            builder:
                (context, state) => ContentWrapper(
                  title: 'My Properties',
                  child: _createPropertiesScreen(context),
                ),
            routes: [
              // Routes for screens using PropertiesProvider (main implementation)
              GoRoute(
                path: 'add',
                builder:
                    (context, state) => ContentWrapper(
                      title: 'Add Property',
                      child: _createPropertyFormScreen(context, null),
                    ),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final propertyId = state.pathParameters['id'];
                  if (propertyId == null) {
                    return const ContentWrapper(
                      title: 'Error',
                      child: Center(child: Text('Error: Missing Property ID')),
                    );
                  }
                  return ContentWrapper(
                    title: 'Property Details',
                    // ✅ CLEAN: Create providers on-demand using factory methods
                    child: _createPropertyDetailsScreen(context, propertyId),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final propertyId = state.pathParameters['id'];
                      if (propertyId == null) {
                        return const ContentWrapper(
                          title: 'Error',
                          child: Center(
                            child: Text('Error: Missing Property ID for Edit'),
                          ),
                        );
                      }
                      return ContentWrapper(
                        title: 'Edit Property',
                        child: _createPropertyFormScreen(context, propertyId),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  ),
),
GoRoute(
  path: '/chat',
  builder: (context, state) {
    final contactId = state.uri.queryParameters['contactId'];
    return ContentWrapper(
      title: 'Messages',
      child: _createChatScreen(context, contactId: contactId),
    );
  },
),
GoRoute(
  path: '/reports',
  builder:
      (context, state) => ContentWrapper(
        title: 'Business Reports',
        child: _createReportsScreen(context),
      ),
),
GoRoute(
  path: '/profile',
  builder:
      (context, state) => ContentWrapper(
        title: 'Profile',
        child: _createProfileScreen(context),
      ),
),
GoRoute(
  path: '/rents',
  builder:
      (context, state) => ContentWrapper(
        title: 'Rental Management',
        child: _createRentsTableScreen(),
      ),
),
// Image carousel route for property images
GoRoute(
  path: '/property-images',
  builder: (context, state) {
    final extras = state.extra as Map<String, dynamic>?;
    final images = extras?['images'] as List<int>? ?? [];
    final initialIndex = extras?['initialIndex'] as int? ?? 0;
    
    return _createImageCarouselScreen(images, initialIndex);
  },
),
      ],
    ),
  );
}
}
