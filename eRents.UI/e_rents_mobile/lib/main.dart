import 'package:e_rents_mobile/providers/auth_provider.dart';
import 'package:e_rents_mobile/providers/booking_provider.dart';
import 'package:e_rents_mobile/providers/property_provider.dart';
import 'package:e_rents_mobile/routes/router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/providers/user_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            routerConfig: MyRouter.router(context), // Pass the GoRouter instance
            theme: ThemeData(
              primarySwatch: Colors.blue,
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
