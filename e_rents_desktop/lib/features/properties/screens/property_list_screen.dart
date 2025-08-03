import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/widgets/desktop_data_table.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:provider/provider.dart';

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  int? _sortColumnIndex;
  bool _sortAscending = true;
  List<Property> _properties = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties({String? sortBy, bool? ascending}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final propertyProvider = Provider.of<PropertyProvider>(
        context,
        listen: false,
      );
      final result =
          sortBy != null
              ? await propertyProvider.loadPropertiesSorted(
                sortBy: sortBy,
                ascending: ascending,
              )
              : await propertyProvider.loadProperties();

      setState(() {
        _properties = result ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    String? sortBy;
    if (_sortColumnIndex != null) {
      final sortFields = ['name', 'price', 'status', 'bedrooms'];
      if (_sortColumnIndex! < sortFields.length) {
        sortBy = sortFields[_sortColumnIndex!];
      }
    }

    await _loadProperties(sortBy: sortBy, ascending: _sortAscending);
  }

  void _handleSort(int? columnIndex, bool ascending) {
    if (columnIndex == null) return;
    
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });

    // Map column index to sort field
    final sortFields = ['name', 'price', 'status', 'bedrooms'];
    if (columnIndex < sortFields.length) {
      _loadProperties(sortBy: sortFields[columnIndex], ascending: ascending);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'rented':
        return Colors.blue;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Properties'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: DesktopDataTable<Property>(
        items: _properties,
        loading: _isLoading,
        errorMessage: _errorMessage,
        onRefresh: _refresh,
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        onSort: _handleSort,
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Price')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Bedrooms')),
        ],
        rowsBuilder: (context, properties) {
          return properties.map((property) {
            return DataRow(
              cells: [
                DataCell(Text(property.name)),
                DataCell(Text('\$${property.price}')),
                DataCell(
                  Chip(
                    label: Text(property.status),
                    backgroundColor: _getStatusColor(property.status),
                  ),
                ),
                DataCell(Text('${property.bedrooms ?? 0}')),
              ],
              onSelectChanged: (_) {
                // Handle row tap
              },
            );
          }).toList();
        },
      ),
    );
  }
}
