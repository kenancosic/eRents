# eRents Desktop Application Routing Documentation

## Overview

This document provides documentation for the routing system used in the eRents desktop application. The application uses `go_router` for navigation with a shell layout pattern and provider injection per route.

## Core Components

### AppRoutes Class

The `AppRoutes` class defines all route names as constants for consistency and type safety:

```dart
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
```

### AppShell

The `AppShell` widget provides the main application layout with navigation:

```dart
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
```

### ContentWrapper

The `ContentWrapper` provides consistent styling for screen content:

```dart
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
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
```

### AppRouter

The main router class that configures all routes and handles navigation logic:

```dart
class AppRouter {
  final GoRouter _router;

  AppRouter._(ApiService api) : _router = GoRouter(
    // Error handler
    errorBuilder: (context, state) => _buildErrorContent(
      state.error?.toString() ?? 'Something went wrong',
    ),
    
    // Redirect logic
    redirect: (context, state) => _redirectLogic(context, state),
    
    // Routes
    routes: _buildRoutes(api),
  );

  static AppRouter create(ApiService api) => AppRouter._(api);

  GoRouter get router => _router;
}
```

## Routing Patterns

### Authentication Guard

The router implements authentication-aware redirection:

```dart
static Future<String?> _redirectLogic(BuildContext context, GoRouterState state) async {
  final authProvider = context.read<AuthProvider>();
  final isLoggedIn = authProvider.isLoggedIn;
  final isAuthRoute = _isAuthRoute(state.uri.path);
  final isPublicRoute = _isPublicRoute(state.uri.path);

  // Redirect authenticated users away from auth routes
  if (isLoggedIn && isAuthRoute) {
    return AppRoutes.home;
  }

  // Redirect unauthenticated users to login
  if (!isLoggedIn && !isPublicRoute && !isAuthRoute) {
    return AppRoutes.login;
  }

  return null;
}
```

### Shell Layout

Most routes use a shell layout with navigation:

```dart
ShellRoute(
  builder: (context, state, child) => AppShell(child: child),
  routes: [
    // Home route
    GoRoute(
      path: AppRoutes.home,
      builder: (context, _) => _buildWrappedContent(
        context,
        'Dashboard',
        (_) => _createHomeScreen(context),
      ),
    ),
    // Other routes with shell layout...
  ],
)
```

### Provider Injection

Each route injects its required providers:

```dart
Widget _createHomeScreen(BuildContext context) {
  return ChangeNotifierProvider(
    create: (context) => HomeProvider(context.read<ApiService>()),
    child: const HomeScreen(),
  );
}
```

### Wrapped Content

Screens are wrapped in a consistent layout:

```dart
Widget _buildWrappedContent(
  BuildContext context,
  String title,
  Widget Function(BuildContext) builder,
) {
  return ContentWrapper(title: title, child: builder(context));
}
```

## Route Structure

### Authentication Routes

- `/login`: Login screen
- `/signup`: Signup screen
- `/forgot-password`: Password reset
- `/verification`: Email verification
- `/create-password`: Password creation

### Main Application Routes

- `/`: Dashboard/home screen
- `/properties`: Property listing
- `/properties/add`: Add new property
- `/properties/:id`: Property details
- `/properties/:id/edit`: Edit property
- `/chat`: Chat interface
- `/reports`: Reports dashboard
- `/profile`: User profile
- `/rents`: Rental management
- `/property-images`: Image carousel

## Navigation Patterns

### Programmatic Navigation

Navigate using GoRouter:

```dart
// Navigate to a route
context.go(AppRoutes.properties);

// Navigate with parameters
context.go('${AppRoutes.properties}/${propertyId}');

// Navigate with extra data
context.push(
  AppRoutes.propertyImages,
  extra: {
    'images': imageIds,
    'initialIndex': selectedIndex,
  },
);
```

### Route Parameters

Handle route parameters:

```dart
GoRoute(
  path: '${AppRoutes.properties}/:id',
  builder: (context, state) {
    final propertyId = state.pathParameters['id']!;
    return _createPropertyDetailsScreen(context, propertyId);
  },
)
```

### Extra Data

Pass extra data between routes:

```dart
// Sending data
context.push(
  AppRoutes.propertyImages,
  extra: {
    'images': imageIds,
    'initialIndex': selectedIndex,
  },
);

// Receiving data
GoRoute(
  path: AppRoutes.propertyImages,
  builder: (context, state) {
    final extras = state.extra as Map<String, dynamic>?;
    final images = extras?['images'] as List<int>? ?? [];
    final initialIndex = extras?['initialIndex'] as int? ?? 0;
    return _createImageCarouselScreen(images, initialIndex);
  },
)
```

## Best Practices

1. **Route Constants**: Use AppRoutes constants for all navigation
2. **Authentication Guard**: Implement proper auth checks
3. **Provider Injection**: Inject providers per route
4. **Consistent Layout**: Use ContentWrapper for screen styling
5. **Error Handling**: Implement errorBuilder for route errors
6. **Shell Layout**: Use shell routes for consistent navigation
7. **Parameter Validation**: Validate route parameters
8. **Type Safety**: Use proper typing for extra data

## Extensibility

The routing system supports easy extension:

1. **New Routes**: Add constants to AppRoutes and configure in _buildRoutes
2. **New Features**: Create factory methods for screen creation
3. **Navigation Guards**: Extend _redirectLogic for new requirements
4. **Layout Variations**: Create new wrapper components
5. **Route Parameters**: Add new parameter handling
6. **Data Passing**: Extend extra data patterns

This routing documentation ensures consistent navigation patterns across the application and provides a solid foundation for future enhancements.
