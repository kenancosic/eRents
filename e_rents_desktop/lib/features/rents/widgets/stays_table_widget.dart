import 'package:e_rents_desktop/features/rents/providers/rents_table_factory.dart';
import 'package:e_rents_desktop/models/rental_display_item.dart';
import 'package:e_rents_desktop/repositories/booking_repository.dart';
import 'package:e_rents_desktop/widgets/table/custom_table_widget.dart';
import 'package:flutter/material.dart';

class StaysTableWidget extends StatelessWidget {
  final BookingRepository bookingRepository;
  final Function(RentalDisplayItem)? onItemTap;
  const StaysTableWidget({
    super.key,
    required this.bookingRepository,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final provider = StaysTableProvider(
      bookingRepository: bookingRepository,
      onItemTap: onItemTap,
    );
    return CustomTableWidget<RentalDisplayItem>(
      dataProvider: provider,
      title: 'Stays',
      searchHint: 'Search by guest or property...',
    );
  }
}
