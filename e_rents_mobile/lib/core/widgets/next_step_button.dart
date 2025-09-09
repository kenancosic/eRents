import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';

class NextStepButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const NextStepButton({
    super.key,
    required this.label,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      label: label,
      isLoading: isLoading,
      onPressed: onPressed,
      width: ButtonWidth.expanded,
    );
  }
}
