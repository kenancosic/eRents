import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_drawer.dart';

class BaseScreen extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;

  BaseScreen({required this.title, required this.body, this.floatingActionButton});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: title),
      drawer: CustomDrawer(),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
