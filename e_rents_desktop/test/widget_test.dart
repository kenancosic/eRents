// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';
import 'package:e_rents_desktop/router.dart';
import 'package:e_rents_desktop/theme/theme.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Setup dependencies for the test environment
    final secureStorage = SecureStorageService();
    final apiService = ApiService('http://localhost:5000', secureStorage);
    final authProvider = AuthProvider(apiService: apiService, storage: secureStorage);
    final appRouter = AppRouter(authProvider);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          // Add other necessary providers for the smoke test here
        ],
        child: MaterialApp.router(
          title: 'eRents Desktop',
          debugShowCheckedModeBanner: false,
          routerConfig: appRouter.router,
          theme: appTheme,
        ),
      ),
    );

    // Verify that the app renders
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
