import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/api_service.dart';
import '../../../widgets/table/custom_table.dart';
import '../providers/rents_provider.dart';

/// A unified table widget for displaying either stays or leases
/// based on the selected rental type
class RentsTableWidget extends StatefulWidget {
  final RentalType rentalType;
  final Function(dynamic)? onItemTap;

  const RentsTableWidget({
    super.key,
    required this.rentalType,
    this.onItemTap,
  });

  @override
  State<RentsTableWidget> createState() => _RentsTableWidgetState();
}

class _RentsTableWidgetState extends State<RentsTableWidget> {
  late RentsProvider _provider;

  @override
  void initState() {
    super.initState();
    
    // Get ApiService from the widget tree
    final apiService = context.read<ApiService>();
    
    // Initialize the provider
    _provider = RentsProvider(apiService, context: context);
    
    // Set the rental type based on the widget parameter
    _provider.setRentalType(widget.rentalType);
    
    // Initial data load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (widget.rentalType == RentalType.stay) {
      await _provider.getPagedStays();
    } else {
      await _provider.getPagedLeases();
    }
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RentsTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update rental type if it changed
    if (oldWidget.rentalType != widget.rentalType) {
      _provider.setRentalType(widget.rentalType);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<RentsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && 
              (provider.stays.isEmpty && provider.leases.isEmpty)) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Use the CustomTableWidget with our provider
          return CustomTableWidget<dynamic>(
            dataProvider: provider,
            title: widget.rentalType == RentalType.stay ? 'Stays' : 'Leases',
            searchHint: widget.rentalType == RentalType.stay ? 'Search stays...' : 'Search leases...',
            onRowTap: widget.onItemTap,
          );
        },
      ),
    );
  }
}
