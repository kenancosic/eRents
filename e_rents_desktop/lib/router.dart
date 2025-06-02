import 'package:e_rents_desktop/features/auth/login_screen.dart';
import 'package:e_rents_desktop/features/auth/signup_screen.dart';
import 'package:e_rents_desktop/features/auth/forgot_password_screen.dart';
import 'package:e_rents_desktop/features/home/home_screen.dart';
import 'package:e_rents_desktop/features/home/providers/home_state_provider.dart';
import 'package:e_rents_desktop/repositories/home_repository.dart';

import 'package:e_rents_desktop/features/maintenance/maintenance_screen.dart';
import 'package:e_rents_desktop/features/maintenance/maintenance_issue_details_screen.dart';
import 'package:e_rents_desktop/features/maintenance/maintenance_form_screen.dart';
import 'package:e_rents_desktop/features/maintenance/providers/maintenance_collection_provider.dart';
import 'package:e_rents_desktop/features/maintenance/providers/maintenance_detail_provider.dart';
import 'package:e_rents_desktop/features/tenants/providers/tenant_collection_provider.dart';
import 'package:e_rents_desktop/features/chat/providers/chat_collection_provider.dart';
import 'package:e_rents_desktop/features/chat/providers/chat_detail_provider.dart';
import 'package:e_rents_desktop/features/chat/chat_screen.dart';
import 'package:e_rents_desktop/repositories/repositories.dart';
import 'package:e_rents_desktop/repositories/tenant_repository.dart';
import 'package:e_rents_desktop/repositories/chat_repository.dart';
import 'package:e_rents_desktop/features/properties/properties_screen.dart';
import 'package:e_rents_desktop/features/properties/property_details_screen.dart';
import 'package:e_rents_desktop/features/properties/property_form_screen.dart';
import 'package:e_rents_desktop/features/statistics/statistics_screen.dart';
import 'package:e_rents_desktop/features/statistics/providers/statistics_state_provider.dart';
import 'package:e_rents_desktop/repositories/statistics_repository.dart';
import 'package:e_rents_desktop/features/reports/providers/reports_state_provider.dart';
import 'package:e_rents_desktop/repositories/reports_repository.dart';
import 'package:e_rents_desktop/features/reports/reports_screen.dart';
import 'package:e_rents_desktop/features/profile/profile_screen.dart';
import 'package:e_rents_desktop/features/profile/providers/profile_state_provider.dart';
import 'package:e_rents_desktop/repositories/profile_repository.dart';
import 'package:e_rents_desktop/features/tenants/tenants_screen.dart';

import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:e_rents_desktop/widgets/app_navigation_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'dart:io';

// ✅ NEW: Import base infrastructure and new providers
import 'features/properties/providers/property_detail_provider.dart';
import 'features/properties/providers/property_stats_provider.dart';
import 'features/properties/providers/property_collection_provider.dart';
import 'main.dart' show getService;

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
                    color: Colors.black.withValues(alpha: 0.1),
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
      // ✅ SIMPLIFIED: Cleaner auth check
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticatedState;

      // Development mode check
      final bool isDevelopmentMode =
          !bool.fromEnvironment('dart.vm.product') ||
          Platform.environment.containsKey('FLUTTER_DEV_MODE');

      if (isDevelopmentMode && isAuthenticated) {
        if (state.uri.path == '/login' ||
            state.uri.path == '/signup' ||
            state.uri.path == '/forgot-password') {
          return '/';
        }
        return null;
      }

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
                (context, state) => ContentWrapper(
                  title: 'Landlord Dashboard',
                  child: _createHomeScreen(),
                ),
          ),
          GoRoute(
            path: '/properties',
            builder:
                (context, state) => ContentWrapper(
                  title: 'My Properties',
                  child: _createPropertiesScreen(),
                ),
            routes: [
              GoRoute(
                path: 'add',
                builder:
                    (context, state) => ContentWrapper(
                      title: 'Add Property',
                      child: _createPropertyFormScreen(null),
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
                    child: _createPropertyDetailsScreen(propertyId),
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
                        child: _createPropertyFormScreen(propertyId),
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
                (context, state) => ContentWrapper(
                  title: 'Maintenance Dashboard',
                  child: _createMaintenanceScreen(),
                ),
          ),
          GoRoute(
            path: '/maintenance/new',
            builder: (context, state) {
              final propertyIdString = state.uri.queryParameters['propertyId'];
              return ContentWrapper(
                title: 'New Maintenance Issue',
                child: _createMaintenanceFormScreen(propertyIdString),
              );
            },
          ),
          GoRoute(
            path: '/maintenance/:id',
            builder: (context, state) {
              final issueIdString = state.pathParameters['id']!;

              // ✅ CLEAN: No more Future.microtask anti-patterns
              return ContentWrapper(
                title: 'Maintenance Issue',
                child: _createMaintenanceDetailsScreen(issueIdString),
              );
            },
          ),
          GoRoute(
            path: '/chat',
            builder:
                (context, state) => ContentWrapper(
                  title: 'Messages',
                  child: _createChatScreen(),
                ),
          ),
          GoRoute(
            path: '/revenue',
            builder:
                (context, state) => ContentWrapper(
                  title: 'Revenue & Analytics',
                  child: _createStatisticsScreen(),
                ),
          ),
          GoRoute(
            path: '/statistics',
            builder:
                (context, state) => ContentWrapper(
                  title: 'Revenue & Analytics',
                  child: _createStatisticsScreen(),
                ),
          ),
          GoRoute(
            path: '/reports',
            builder:
                (context, state) => ContentWrapper(
                  title: 'Business Reports',
                  child: _createReportsScreen(),
                ),
          ),
          GoRoute(
            path: '/profile',
            builder:
                (context, state) => ContentWrapper(
                  title: 'Profile',
                  child: _createProfileScreen(),
                ),
          ),
          GoRoute(
            path: '/tenants',
            builder:
                (context, state) => ContentWrapper(
                  title: 'Tenant Management',
                  child: _createTenantsScreen(),
                ),
          ),
        ],
      ),
    ],
  );

  // ✅ NEW: Factory methods for creating screens with providers
  static Widget _createHomeScreen() {
    return ChangeNotifierProvider(
      create:
          (_) =>
              HomeStateProvider(getService<HomeRepository>())
                ..loadDashboardData(),
      child: const HomeScreen(),
    );
  }

  static Widget _createPropertyDetailsScreen(String propertyId) {
    return MultiProvider(
      providers: [
        // Create providers on-demand using ServiceLocator
        ChangeNotifierProvider(
          create:
              (_) =>
                  PropertyDetailProvider(getService())
                    ..loadPropertyById(int.parse(propertyId)),
        ),
        ChangeNotifierProvider(
          create:
              (_) => PropertyStatsProvider(
                getService(), // StatisticsService
                getService(), // BookingService
              )..loadPropertyStats(propertyId),
        ),
      ],
      child: PropertyDetailsScreen(propertyId: propertyId),
    );
  }

  static Widget _createPropertiesScreen() {
    return ChangeNotifierProvider(
      create: (_) => PropertyCollectionProvider(getService())..fetchItems(),
      child: const PropertiesScreen(),
    );
  }

  static Widget _createMaintenanceDetailsScreen(String issueId) {
    // Create MaintenanceDetailProvider on-demand with automatic data loading
    return ChangeNotifierProvider(
      create:
          (_) =>
              MaintenanceDetailProvider(getService<MaintenanceRepository>())
                ..loadMaintenanceIssueById(int.parse(issueId)),
      child: MaintenanceIssueDetailsScreen(
        issueId: issueId,
        issue: null, // Will be loaded by provider
      ),
    );
  }

  static Widget _createPropertyFormScreen(String? propertyId) {
    if (propertyId == null) {
      // Add mode - only need PropertyCollectionProvider
      return ChangeNotifierProvider(
        create: (_) => PropertyCollectionProvider(getService()),
        child: const PropertyFormScreen(propertyId: null),
      );
    } else {
      // Edit mode - need both PropertyDetailProvider and PropertyCollectionProvider
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create:
                (_) =>
                    PropertyDetailProvider(getService())
                      ..loadPropertyById(int.parse(propertyId)),
          ),
          ChangeNotifierProvider(
            create: (_) => PropertyCollectionProvider(getService()),
          ),
        ],
        child: PropertyFormScreen(propertyId: propertyId),
      );
    }
  }

  static Widget _createMaintenanceScreen() {
    return ChangeNotifierProvider(
      create:
          (_) =>
              MaintenanceCollectionProvider(getService<MaintenanceRepository>())
                ..fetchItems(),
      child: const MaintenanceScreen(),
    );
  }

  static Widget _createMaintenanceFormScreen(String? propertyId) {
    return ChangeNotifierProvider(
      create:
          (_) => MaintenanceCollectionProvider(
            getService<MaintenanceRepository>(),
          ),
      child: MaintenanceFormScreen(
        propertyId: propertyId != null ? int.parse(propertyId) : null,
      ),
    );
  }

  static Widget _createTenantsScreen() {
    return ChangeNotifierProvider(
      create:
          (_) =>
              TenantCollectionProvider(getService<TenantRepository>())
                ..loadAllData(),
      child: const TenantsScreen(),
    );
  }

  static Widget _createChatScreen() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create:
              (_) =>
                  ChatCollectionProvider(getService<ChatRepository>())
                    ..loadAllData(),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatDetailProvider(getService<ChatRepository>()),
        ),
      ],
      child: const ChatScreen(),
    );
  }

  static Widget _createStatisticsScreen() {
    return ChangeNotifierProvider(
      create:
          (_) =>
              StatisticsStateProvider(getService<StatisticsRepository>())
                ..loadFinancialStatistics(),
      child: const StatisticsScreen(),
    );
  }

  static Widget _createReportsScreen() {
    return ChangeNotifierProvider(
      create:
          (_) =>
              ReportsStateProvider(getService<ReportsRepository>())
                ..loadCurrentReportData(),
      child: const ReportsScreen(),
    );
  }

  static Widget _createProfileScreen() {
    return ChangeNotifierProvider(
      create:
          (_) =>
              ProfileStateProvider(getService<ProfileRepository>())
                ..loadUserProfile(),
      child: const ProfileScreen(),
    );
  }
}
