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
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/features/maintenance/providers/maintenance_provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AppRouter {
  final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // If we're in development mode and have a token, allow navigation
      if (AuthService.isDevelopmentMode && AuthService.hasToken) {
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

      if (!isAuthRoute) {
        return '/login';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      // Main routes
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/properties',
        builder: (context, state) => const PropertiesScreen(),
      ),
      GoRoute(
        path: '/properties/:id',
        builder: (context, state) {
          final property = state.extra as Property?;
          if (property == null) {
            // If no property is passed, try to find it in the provider
            final propertyProvider = context.read<PropertyProvider>();
            final propertyId = state.pathParameters['id']!;
            final foundProperty = propertyProvider.properties.firstWhere(
              (p) => p.id == propertyId,
              orElse: () => throw Exception('Property not found'),
            );
            return PropertyDetailsScreen(property: foundProperty);
          }
          return PropertyDetailsScreen(property: property);
        },
      ),
      GoRoute(
        path: '/properties/edit/:id',
        builder: (context, state) {
          final property = state.extra as Property;
          return PropertyFormScreen(property: property);
        },
      ),
      GoRoute(
        path: '/maintenance',
        builder: (context, state) => const MaintenanceScreen(),
      ),
      GoRoute(
        path: '/maintenance/new',
        builder: (context, state) {
          final propertyId = state.uri.queryParameters['propertyId'];
          return MaintenanceFormScreen(propertyId: propertyId);
        },
      ),
      GoRoute(
        path: '/maintenance/:id',
        builder: (context, state) {
          final maintenanceProvider = context.read<MaintenanceProvider>();
          final propertyProvider = context.read<PropertyProvider>();
          final issueId = state.pathParameters['id']!;

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
            issue = maintenanceProvider.issues.firstWhere(
              (i) => i.id == issueId,
            );
          } catch (_) {
            // Issue will be loaded after fetchIssues completes
          }

          // Return the screen even if the issue isn't loaded yet
          // The screen should handle the loading state
          return MaintenanceIssueDetailsScreen(issueId: issueId, issue: issue);
        },
      ),
      GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
      GoRoute(
        path: '/statistics',
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/tenants',
        builder: (context, state) => const TenantsScreen(),
      ),
    ],
  );
}
