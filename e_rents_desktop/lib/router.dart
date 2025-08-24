// router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:io';

// All features through centralized import
import 'package:e_rents_desktop/features/features.dart';

// Widgets
import 'package:e_rents_desktop/widgets/app_navigation_bar.dart';
import 'package:e_rents_desktop/features/properties/widgets/image_carousel_dialog.dart';

// Services

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
  static const String maintenance = '/maintenance';
  static const String profile = '/profile';
  static const String rents = '/rents';
  static const String propertyImages = '/property-images';
  static const String tenants = '/tenants';
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

        // Tenants
        GoRoute(
          path: AppRoutes.tenants,
          builder: (context, _) => _buildWrappedContent(
            context,
            'Tenants',
            _createTenantsScreen,
          ),
        ),

        // Maintenance
        GoRoute(
          path: AppRoutes.maintenance,
          builder: (context, _) => _buildWrappedContent(
            context,
            'Maintenance',
            _createMaintenanceScreen,
          ),
          routes: [
            // New Issue
            GoRoute(
              path: 'new',
              builder: (context, _) => _buildWrappedContent(
                context,
                'New Maintenance Issue',
                _createMaintenanceFormScreen,
              ),
            ),
            // Issue Details
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final issueId = state.pathParameters['id'];
                if (issueId == null) {
                  return _buildErrorContent('Missing Maintenance Issue ID');
                }
                return _buildWrappedContent(
                  context,
                  'Issue Details',
                  (ctx) => _createMaintenanceIssueDetailsScreen(ctx, issueId),
                );
              },
              routes: [
                // Edit Issue
                GoRoute(
                  path: 'edit',
                  builder: (context, state) {
                    final issueId = state.pathParameters['id'];
                    if (issueId == null) {
                      return _buildErrorContent('Missing Maintenance Issue ID for Edit');
                    }
                    return _buildWrappedContent(
                      context,
                      'Edit Maintenance Issue',
                      (ctx) {
                        // Ensure the issue is loaded before showing the form
                        return FutureBuilder<void>(
                          future: ctx.read<MaintenanceProvider>().getById(issueId),
                          builder: (ctx2, snap) {
                            if (snap.connectionState != ConnectionState.done) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final issue = ctx2.read<MaintenanceProvider>().selectedIssue;
                            if (issue == null) {
                              return _buildErrorContent('Issue not found');
                            }
                            return MaintenanceFormScreen(issue: issue);
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ],
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
    // Use the globally registered HomeProvider from FeaturesRegistry (main.dart)
    // Avoid creating a new provider here that reads ApiService from context,
    // since ApiService is not provided via Provider but passed into providers directly.
    return const HomeScreen();
  }

  Widget _createPropertyDetailsScreen(BuildContext context, String propertyId) {
    // Delegate data loading to the screen to avoid duplicate fetches
    return PropertyDetailScreen(propertyId: int.parse(propertyId));
  }

  Widget _createPropertiesScreen(BuildContext context) {
    // Delegate initial load to the screen/provider to avoid duplicate fetches
    return const PropertyListScreen();
  }

  Widget _createPropertyFormScreen(BuildContext context, String? propertyId) {
    // Let the form screen handle its own loading logic; prevents duplicate GET-by-id
    if (propertyId != null) {
      return PropertyFormScreen(propertyId: int.parse(propertyId));
    }
    return const PropertyFormScreen(propertyId: null);
  }

  Widget _createChatScreen(BuildContext context, {String? contactId}) {
    // Use the globally registered ChatProvider and trigger initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadContacts();
    });
    return ChatScreen(contactId: contactId);
  }

  Widget _createReportsScreen(BuildContext context) {
    // Use the globally registered ReportsProvider and trigger initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().fetchCurrentReports();
    });
    return const ReportsScreen();
  }

  // Profile screen factory
  Widget _createProfileScreen(BuildContext context) {
    // Use the globally registered ProfileProvider and trigger initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadUserProfile();
    });
    return const ProfileScreen();
  }

  // Tenants screen factory
  Widget _createTenantsScreen(BuildContext context) {
    return const TenantsListScreen();
  }

  // Rents screen factory
  Widget _createRentsTableScreen() {
    return const RentsScreen();
  }

  // Image carousel factory
  Widget _createImageCarouselScreen(List<int> images, int initialIndex) {
    return ImageCarouselDialog(images: images, initialIndex: initialIndex);
  }

  // Maintenance factories
  Widget _createMaintenanceScreen(BuildContext context) {
    return const MaintenanceScreen();
  }

  Widget _createMaintenanceIssueDetailsScreen(BuildContext context, String issueId) {
    return MaintenanceIssueDetailsScreen(issueId: issueId);
  }

  Widget _createMaintenanceFormScreen(BuildContext context) {
    return const MaintenanceFormScreen();
  }
}
