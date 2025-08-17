import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/enums/property_status.dart';

extension PropertyStatusUI on PropertyStatus {
  Color get uiColor {
    switch (this) {
      case PropertyStatus.available:
        return Colors.green;
      case PropertyStatus.occupied:
        return Colors.orange;
      case PropertyStatus.underMaintenance:
        return Colors.blue;
      case PropertyStatus.unavailable:
        return Colors.grey;
    }
  }

  IconData get uiIcon {
    switch (this) {
      case PropertyStatus.available:
        return Icons.check_circle_outline;
      case PropertyStatus.occupied:
        return Icons.person_outline;
      case PropertyStatus.underMaintenance:
        return Icons.build_circle_outlined;
      case PropertyStatus.unavailable:
        return Icons.help_outline;
    }
  }
}
