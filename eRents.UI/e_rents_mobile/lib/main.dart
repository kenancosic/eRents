import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/providers/user_provider.dart';

final LocalStorage localStorage = LocalStorage('localstorage.json');
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Stripe and other services here if necessary
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // Add more providers as needed
      ],
      child: MaterialApp(
        routerConfig: router,
        title: 'Your App Title',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          // Customize your app theme as needed
        ),
        home: YourHomeWidget(), // Replace with your home widget
        // Set up your routing if using named routes
      ),
    );
  }
}
