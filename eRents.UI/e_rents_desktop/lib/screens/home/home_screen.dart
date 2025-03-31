import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title: 'Home',
      currentPath: '/',
      child: Center(
        child: Text(
          'Welcome to eRents',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
