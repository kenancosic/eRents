import 'package:e_rents_mobile/core/widgets/custom_drawer.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class BaseScreen extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final bool showAppBar;

  const BaseScreen(
      {super.key, 
      required this.title,
      required this.body,
      this.floatingActionButton,
      this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar ? CustomAppBar(title: title) : null,
      drawer: CustomDrawer(),
      body: Padding(padding: const EdgeInsets.all(16.0), child: body),
      floatingActionButton: floatingActionButton,
    );
  }

    void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
