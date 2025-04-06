import 'package:e_rents_desktop/screens/auth/login_screen.dart';
import 'package:e_rents_desktop/screens/auth/signup_screen.dart';
import 'package:e_rents_desktop/screens/auth/forgot_password_screen.dart';
import 'package:e_rents_desktop/screens/home/home_screen.dart';
import 'package:e_rents_desktop/screens/chat/chat_screen.dart';
import 'package:e_rents_desktop/screens/maintenance/maintenance_screen.dart';
import 'package:e_rents_desktop/screens/properties/properties_screen.dart';
import 'package:e_rents_desktop/screens/statistics/statistics_screen.dart';
import 'package:e_rents_desktop/screens/reports/reports_screen.dart';
import 'package:e_rents_desktop/screens/profile/profile_screen.dart';
import 'package:e_rents_desktop/screens/settings/settings_screen.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  final GoRouter router = GoRouter(
    initialLocation: '/login',
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

      // Main app routes
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
      GoRoute(
        path: '/properties',
        builder: (context, state) => const PropertiesScreen(),
      ),
      GoRoute(
        path: '/maintenance',
        builder: (context, state) => const MaintenanceScreen(),
      ),
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
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );

  // static Route<dynamic> generateRoute(RouteSettings settings) {
  //   switch (settings.name) {
  //     case '/':
  //       return MaterialPageRoute(builder: (_) => HomeScreen());
  //     default:
  //       return MaterialPageRoute(
  //         builder: (_) => Scaffold(
  //           body: Center(
  //             child: Text('No route defined for ${settings.name}'),
  //           ),
  //         ),
  //       );
  //   }
  // }
}
