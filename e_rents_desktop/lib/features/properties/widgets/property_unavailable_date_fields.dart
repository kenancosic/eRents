import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';

/// A reusable widget for selecting unavailable date range for a property
class PropertyUnavailableDateFields extends StatefulWidget {
  final Property? property;
  final Function(DateTime?, DateTime?) onDateChanged;

  const PropertyUnavailableDateFields({super.key, required this.property, required this.onDateChanged});

  @override
  State<PropertyUnavailableDateFields> createState() => _PropertyUnavailableDateFieldsState();
}

class _PropertyUnavailableDateFieldsState extends State<PropertyUnavailableDateFields> {
  DateTime? _unavailableFrom;
  DateTime? _unavailableTo;

  @override
  void initState() {
    super.initState();
    _unavailableFrom = widget.property?.unavailableFrom;
    _unavailableTo = widget.property?.unavailableTo;
  }

  Future<void> _selectDate(bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _unavailableFrom = picked;
        } else {
          _unavailableTo = picked;
        }
        widget.onDateChanged(_unavailableFrom, _unavailableTo);
      });
    }
  }

  void _clearDate(bool isFrom) {
    setState(() {
      if (isFrom) {
        _unavailableFrom = null;
      } else {
        _unavailableTo = null;
      }
      widget.onDateChanged(_unavailableFrom, _unavailableTo);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Unavailable Date Range',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(true),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Unavailable From',
                    border: const OutlineInputBorder(),
                    suffixIcon: _unavailableFrom != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _clearDate(true),
                            tooltip: 'Clear date',
                          )
                        : null,
                  ),
                  child: Text(_unavailableFrom == null
                      ? 'Select date'
                      : '${_unavailableFrom!.year}-${_unavailableFrom!.month.toString().padLeft(2, '0')}-${_unavailableFrom!.day.toString().padLeft(2, '0')}'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(false),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Unavailable To',
                    border: const OutlineInputBorder(),
                    suffixIcon: _unavailableTo != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _clearDate(false),
                            tooltip: 'Clear date',
                          )
                        : null,
                  ),
                  child: Text(_unavailableTo == null
                      ? 'Select date'
                      : '${_unavailableTo!.year}-${_unavailableTo!.month.toString().padLeft(2, '0')}-${_unavailableTo!.day.toString().padLeft(2, '0')}'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
