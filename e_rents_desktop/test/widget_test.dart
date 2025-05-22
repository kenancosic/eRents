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

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>(
            create:
                (_) =>
                    ApiService('http://localhost:5000', SecureStorageService()),
          ),
        ],
        child: MaterialApp.router(
          title: 'eRents Desktop',
          debugShowCheckedModeBanner: false,
          routerConfig: AppRouter().router,
          theme: appTheme,
        ),
      ),
    );

    // Verify that the app renders
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
