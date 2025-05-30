import 'package:e_rents_desktop/features/auth/login_screen.dart';
import 'package:e_rents_desktop/features/auth/signup_screen.dart';
import 'package:e_rents_desktop/features/auth/forgot_password_screen.dart';
import 'package:e_rents_desktop/features/home/home_screen.dart';
import 'package:e_rents_desktop/features/chat/chat_screen.dart';
import 'package:e_rents_desktop/features/maintenance/maintenance_screen.dart';
import 'package:e_rents_desktop/features/maintenance/maintenance_issue_details_screen.dart';
import 'package:e_rents_desktop/features/maintenance/maintenance_form_screen.dart';
import 'package:e_rents_desktop/features/properties/properties_screen.dart';
import 'package:e_rents_desktop/features/properties/property_details_screen.dart';
import 'package:e_rents_desktop/features/properties/property_form_screen.dart';
import 'package:e_rents_desktop/features/statistics/statistics_screen.dart';
import 'package:e_rents_desktop/features/reports/reports_screen.dart';
import 'package:e_rents_desktop/features/profile/profile_screen.dart';
import 'package:e_rents_desktop/features/tenants/tenants_screen.dart';
import 'package:e_rents_desktop/services/auth_service.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/features/maintenance/providers/maintenance_provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:e_rents_desktop/widgets/app_navigation_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'dart:io';

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
                    color: Colors.black.withOpacity(0.1),
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
  final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      // Check authentication status using auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticatedState;

      // Development mode check
      final bool isDevelopmentMode =
          // Check some environment variable, or you can hardcode for development
          !bool.fromEnvironment('dart.vm.product') ||
          Platform.environment.containsKey('FLUTTER_DEV_MODE');

      // If we're in development mode and authenticated, allow navigation
      if (isDevelopmentMode && isAuthenticated) {
        if (state.uri.path == '/login' ||
            state.uri.path == '/signup' ||
            state.uri.path == '/forgot-password') {
          return '/';
        }
        return null;
      }

      // If not authenticated and not on auth routes, redirect to login
      final isAuthRoute =
          state.uri.path == '/login' ||
          state.uri.path == '/signup' ||
          state.uri.path == '/forgot-password';

      if (!isAuthRoute && !isAuthenticated) {
        return '/login';
      }

      return null;
    },
    routes: [
      // Auth routes (no shell - they use their own layout)
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main app shell with persistent navigation
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // Main routes
          GoRoute(
            path: '/',
            builder:
                (context, state) => const ContentWrapper(
                  title: 'Landlord Dashboard',
                  child: HomeScreen(),
                ),
          ),
          GoRoute(
            path: '/properties',
            builder:
                (context, state) => const ContentWrapper(
                  title: 'My Properties',
                  child: PropertiesScreen(),
                ),
            routes: [
              GoRoute(
                path: 'add',
                builder:
                    (context, state) => const ContentWrapper(
                      title: 'Add Property',
                      child: PropertyFormScreen(propertyId: null),
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
                    child: PropertyDetailsScreen(propertyId: propertyId),
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
                        child: PropertyFormScreen(propertyId: propertyId),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/maintenance',
            builder:
                (context, state) => const ContentWrapper(
                  title: 'Maintenance Dashboard',
                  child: MaintenanceScreen(),
                ),
          ),
          GoRoute(
            path: '/maintenance/new',
            builder: (context, state) {
              final propertyIdString = state.uri.queryParameters['propertyId'];
              final int? propertyId =
                  propertyIdString == null
                      ? null
                      : int.tryParse(propertyIdString);
              return ContentWrapper(
                title: 'New Maintenance Issue',
                child: MaintenanceFormScreen(propertyId: propertyId),
              );
            },
          ),
          GoRoute(
            path: '/maintenance/:id',
            builder: (context, state) {
              final maintenanceProvider = context.read<MaintenanceProvider>();
              final propertyProvider = context.read<PropertyProvider>();
              final issueIdString = state.pathParameters['id']!;
              final issueId = int.tryParse(issueIdString);

              // Instead of fetching immediately, schedule it for after the build
              Future.microtask(() {
                if (maintenanceProvider.issues.isEmpty) {
                  maintenanceProvider.fetchIssues();
                }
                if (propertyProvider.properties.isEmpty) {
                  propertyProvider.fetchProperties();
                }
              });

              // Try to find the issue if it already exists
              MaintenanceIssue? issue;
              try {
                if (issueId != null) {
                  issue = maintenanceProvider.issues.firstWhere(
                    (i) => i.id == issueId,
                  );
                }
              } catch (_) {
                // Issue will be loaded after fetchIssues completes
              }

              // Return the screen even if the issue isn't loaded yet
              // The screen should handle the loading state
              return ContentWrapper(
                title: 'Maintenance Issue',
                child: MaintenanceIssueDetailsScreen(
                  issueId: issueIdString,
                  issue: issue,
                ),
              );
            },
          ),
          GoRoute(
            path: '/chat',
            builder:
                (context, state) => const Scaffold(
                  body: Center(
                    child: Text(
                      'Chat feature is temporarily disabled for system maintenance',
                    ),
                  ),
                ),
          ),
          GoRoute(
            path: '/revenue',
            builder:
                (context, state) => const ContentWrapper(
                  title: 'Revenue & Analytics',
                  child: StatisticsScreen(),
                ),
          ),
          GoRoute(
            path: '/reports',
            builder:
                (context, state) => const ContentWrapper(
                  title: 'Business Reports',
                  child: ReportsScreen(),
                ),
          ),
          GoRoute(
            path: '/profile',
            builder:
                (context, state) => const ContentWrapper(
                  title: 'Profile',
                  child: ProfileScreen(),
                ),
          ),
          GoRoute(
            path: '/tenants',
            builder:
                (context, state) => const Scaffold(
                  body: Center(
                    child: Text('Tenants feature temporarily disabled'),
                  ),
                ),
          ),
        ],
      ),
    ],
  );
}
