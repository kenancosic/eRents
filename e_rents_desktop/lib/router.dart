// router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:io';

// Auth
import 'package:e_rents_desktop/features/auth/login_screen.dart';
import 'package:e_rents_desktop/features/auth/verification_screen.dart';
import 'package:e_rents_desktop/features/auth/create_password_screen.dart';
import 'package:e_rents_desktop/features/auth/signup_screen.dart';
import 'package:e_rents_desktop/features/auth/forgot_password_screen.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';

// Home
import 'package:e_rents_desktop/features/home/home_screen.dart';
import 'package:e_rents_desktop/features/home/providers/home_provider.dart';

// Properties
import 'package:e_rents_desktop/features/properties/screens/property_list_screen.dart';
import 'package:e_rents_desktop/features/properties/screens/property_detail_screen.dart';
import 'package:e_rents_desktop/features/properties/screens/property_form_screen.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_images_grid.dart';

// Chat
import 'package:e_rents_desktop/features/chat/chat_screen.dart';
import 'package:e_rents_desktop/features/chat/providers/chat_provider.dart';

// Reports
import 'package:e_rents_desktop/features/reports/reports_screen.dart';
import 'package:e_rents_desktop/features/reports/providers/reports_provider.dart';

// Profile
import 'package:e_rents_desktop/features/profile/profile_screen.dart';
import 'package:e_rents_desktop/features/profile/providers/profile_provider.dart';

// Rents
import 'package:e_rents_desktop/features/rents/rents_screen.dart';

// Widgets
import 'package:e_rents_desktop/widgets/app_navigation_bar.dart';

// Services
import 'services/api_service.dart';

// Route names as constants
class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String verification = '/verification';
  static const String createPassword = '/create-password';
  static const String home = '/';
  static const String properties = '/properties';
  static const String addProperty = 'add';
  static const String propertyDetails = ':id';
  static const String editProperty = 'edit';
  static const String chat = '/chat';
  static const String reports = '/reports';
  static const String profile = '/profile';
  static const String rents = '/rents';
  static const String propertyImages = '/property-images';
}

// Shell layout with navigation
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

// Content wrapper for consistent styling
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
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
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

  AppRouter(this.authProvider) {
    router = GoRouter(
      initialLocation: AppRoutes.home,
      refreshListenable: authProvider,
      debugLogDiagnostics: true,
      redirect: _redirectLogic,
      routes: _buildRoutes(),
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text('Page not found: ${state.uri.path}')),
      ),
    );
  }

  String? _redirectLogic(BuildContext context, GoRouterState state) {
    final isAuthenticated = authProvider.isAuthenticated;
    final isDevelopmentMode =
        !bool.fromEnvironment('dart.vm.product') ||
        Platform.environment.containsKey('FLUTTER_DEV_MODE');

    // Development mode handling
    if (isDevelopmentMode && isAuthenticated) {
      if (state.uri.path == AppRoutes.login) return AppRoutes.home;
    }

    // Auth route handling
    final isAuthRoute = _isAuthRoute(state.uri.path);
    if (isAuthenticated && isAuthRoute) return AppRoutes.home;
    if (!isAuthenticated && !isAuthRoute && !_isPublicRoute(state.uri.path)) {
      return AppRoutes.login;
    }

    return null;
  }

  bool _isAuthRoute(String path) => [
    AppRoutes.login,
    AppRoutes.signup,
    AppRoutes.forgotPassword,
  ].contains(path);

  bool _isPublicRoute(String path) =>
      [AppRoutes.verification, AppRoutes.createPassword].contains(path);

  List<RouteBase> _buildRoutes() => [
    // Public routes
    GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
    GoRoute(path: AppRoutes.signup, builder: (_, __) => const SignupScreen()),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (_, __) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.verification,
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        return VerificationScreen(email: email);
      },
    ),
    GoRoute(
      path: AppRoutes.createPassword,
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        final code = state.uri.queryParameters['code'] ?? '';
        return CreatePasswordScreen(email: email, code: code);
      },
    ),

    // Main app shell with protected routes
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        // Home
        GoRoute(
          path: AppRoutes.home,
          builder: (context, _) => _buildWrappedContent(
            context,
            'Landlord Dashboard',
            _createHomeScreen,
          ),
        ),

        // Properties
        GoRoute(
          path: AppRoutes.properties,
          builder: (context, _) => _buildWrappedContent(
            context,
            'My Properties',
            _createPropertiesScreen,
          ),
          routes: [
            // Add Property
            GoRoute(
              path: AppRoutes.addProperty,
              builder: (context, _) => _buildWrappedContent(
                context,
                'Add Property',
                (ctx) => _createPropertyFormScreen(ctx, null),
              ),
            ),

            // Property Details
            GoRoute(
              path: AppRoutes.propertyDetails,
              builder: (context, state) {
                final propertyId = state.pathParameters['id'];
                if (propertyId == null) {
                  return _buildErrorContent('Missing Property ID');
                }
                return _buildWrappedContent(
                  context,
                  'Property Details',
                  (ctx) => _createPropertyDetailsScreen(ctx, propertyId),
                );
              },
              routes: [
                // Edit Property
                GoRoute(
                  path: AppRoutes.editProperty,
                  builder: (context, state) {
                    final propertyId = state.pathParameters['id'];
                    if (propertyId == null) {
                      return _buildErrorContent('Missing Property ID for Edit');
                    }
                    return _buildWrappedContent(
                      context,
                      'Edit Property',
                      (ctx) => _createPropertyFormScreen(ctx, propertyId),
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        // Chat
        GoRoute(
          path: AppRoutes.chat,
          builder: (context, state) {
            final contactId = state.uri.queryParameters['contactId'];
            return _buildWrappedContent(
              context,
              'Messages',
              (ctx) => _createChatScreen(ctx, contactId: contactId),
            );
          },
        ),

        // Reports
        GoRoute(
          path: AppRoutes.reports,
          builder: (context, _) => _buildWrappedContent(
            context,
            'Business Reports',
            _createReportsScreen,
          ),
        ),

        // Profile
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, _) =>
              _buildWrappedContent(context, 'Profile', _createProfileScreen),
        ),

        // Rents
        GoRoute(
          path: AppRoutes.rents,
          builder: (context, _) => _buildWrappedContent(
            context,
            'Rental Management',
            (_) => _createRentsTableScreen(),
          ),
        ),

        // Property Images
        GoRoute(
          path: AppRoutes.propertyImages,
          builder: (context, state) {
            final extras = state.extra as Map<String, dynamic>?;
            final images = extras?['images'] as List<int>? ?? [];
            final initialIndex = extras?['initialIndex'] as int? ?? 0;
            return _createImageCarouselScreen(images, initialIndex);
          },
        ),
      ],
    ),
  ];

  // Helper method to create wrapped content
  Widget _buildWrappedContent(
    BuildContext context,
    String title,
    Widget Function(BuildContext) builder,
  ) {
    return ContentWrapper(title: title, child: builder(context));
  }

  // Error content builder
  Widget _buildErrorContent(String message) {
    return ContentWrapper(
      title: 'Error',
      child: Center(child: Text(message)),
    );
  }

  // Factory methods for creating screens with providers
  Widget _createHomeScreen(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeProvider(context.read<ApiService>()),
      child: const HomeScreen(),
    );
  }

  Widget _createPropertyDetailsScreen(BuildContext context, String propertyId) {
    // Use the existing PropertyProvider from the widget tree
    final propertyProvider = context.read<PropertyProvider>();
    propertyProvider.loadProperty(int.parse(propertyId));
    
    return Consumer<PropertyProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null) {
          return Center(child: Text('Error: ${provider.error}'));
        }
        return PropertyDetailScreen(propertyId: int.parse(propertyId));
      },
    );
  }

  Widget _createPropertiesScreen(BuildContext context) {
    // Use the existing PropertyProvider from the widget tree
    final propertyProvider = context.read<PropertyProvider>();
    propertyProvider.loadProperties();
    
    return const PropertyListScreen();
  }

  Widget _createPropertyFormScreen(BuildContext context, String? propertyId) {
    // Use the existing PropertyProvider from the widget tree
    final propertyProvider = context.read<PropertyProvider>();
    
    if (propertyId != null) {
      propertyProvider.loadProperty(int.parse(propertyId));
      return Consumer<PropertyProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }
          return PropertyFormScreen(propertyId: int.parse(propertyId));
        },
      );
    }
    
    return const PropertyFormScreen(propertyId: null);
  }

  Widget _createChatScreen(BuildContext context, {String? contactId}) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(context.read<ApiService>())..loadContacts(),
      child: ChatScreen(contactId: contactId),
    );
  }

  Widget _createReportsScreen(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          ReportsProvider(context.read<ApiService>())..fetchCurrentReports(),
      child: const ReportsScreen(),
    );
  }

  // Profile screen factory
  Widget _createProfileScreen(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          ProfileProvider(context.read<ApiService>())..loadUserProfile(),
      child: const ProfileScreen(),
    );
  }

  // Rents screen factory
  Widget _createRentsTableScreen() {
    return const RentsScreen();
  }

  // Image carousel factory
  Widget _createImageCarouselScreen(List<int> images, int initialIndex) {
    return ImageCarouselDialog(images: images, initialIndex: initialIndex);
  }
}
