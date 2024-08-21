import 'dart:async';

import 'package:e_rents_mobile/routes/router.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Log errors or send to an analytics service
  };
  runZonedGuarded(() {
    runApp(MyApp());
  }, (error, stackTrace) {
    // Log errors or send to an analytics service
  });
}

class MyApp extends StatelessWidget {
  // Initialize the AppRouter
  final AppRouter _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'eRents',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routerConfig: _appRouter.router, // Use the GoRouter configuration
      debugShowCheckedModeBanner: false,
    );
  }
}
