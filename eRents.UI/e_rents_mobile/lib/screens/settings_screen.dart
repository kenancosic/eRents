import 'package:e_rents_mobile/providers/preference_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../routes/base_screen.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Settings',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Consumer<PreferencesProvider>(
              builder: (context, provider, child) {
                return SwitchListTile(
                  title: Text('Dark Mode'),
                  value: false, // Get the value from preferences
                  onChanged: (bool value) {
                    provider.setPreference('dark_mode', value.toString());
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
