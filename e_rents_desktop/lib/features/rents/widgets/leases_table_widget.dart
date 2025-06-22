import 'package:e_rents_desktop/features/rents/providers/rents_table_factory.dart';
import 'package:e_rents_desktop/models/rental_display_item.dart';
import 'package:e_rents_desktop/repositories/rental_request_repository.dart';
import 'package:e_rents_desktop/widgets/table/custom_table_widget.dart';
import 'package:flutter/material.dart';

class LeasesTableWidget extends StatelessWidget {
  final RentalRequestRepository rentalRequestRepository;
  final Function(RentalDisplayItem)? onItemTap;

  const LeasesTableWidget({
    super.key,
    required this.rentalRequestRepository,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: When LeaseDetailScreen is created, this will navigate to it.
    final provider = LeasesTableProvider(
      rentalRequestRepository: rentalRequestRepository,
      onItemTap: onItemTap,
    );

    return CustomTableWidget<RentalDisplayItem>(
      dataProvider: provider,
      title: 'Leases',
      searchHint: 'Search by tenant or property...',
    );
  }
}
