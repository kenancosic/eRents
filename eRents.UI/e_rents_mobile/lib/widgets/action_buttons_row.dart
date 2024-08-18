import 'package:flutter/material.dart';

class ActionButtonsRow extends StatelessWidget {
  final List<ActionButtonData> buttons;

  const ActionButtonsRow({
    Key? key,
    required this.buttons,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: buttons
          .map((button) => ElevatedButton.icon(
                onPressed: button.onPressed,
                icon: Icon(button.icon),
                label: Text(button.label),
              ))
          .toList(),
    );
  }
}

class ActionButtonData {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  ActionButtonData({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
}
