import 'package:e_rents_desktop/features/rents/providers/rents_table_factory.dart';
import 'package:e_rents_desktop/services/rental_management_service.dart';
import 'package:flutter/material.dart';

class StaysTableWidget extends StatelessWidget {
  final RentalManagementService rentalManagementService;
  const StaysTableWidget({Key? key, required this.rentalManagementService})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RentsTableFactory.createStaysTable(rentalManagementService);
  }
}
