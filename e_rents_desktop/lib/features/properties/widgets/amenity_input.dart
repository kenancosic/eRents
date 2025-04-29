import 'package:flutter/material.dart';

/// A widget for selecting and displaying amenities using chips.
class AmenityInput extends StatefulWidget {
  final List<String> initialAmenities;
  final Map<String, IconData> availableAmenitiesWithIcons;
  final Function(List<String> updatedAmenities) onChanged;

  const AmenityInput({
    super.key,
    required this.initialAmenities,
    required this.availableAmenitiesWithIcons,
    required this.onChanged,
  });

  @override
  State<AmenityInput> createState() => _AmenityInputState();
}

class _AmenityInputState extends State<AmenityInput> {
  late List<String> _selectedAmenities;
  late TextEditingController _amenityController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedAmenities = List.from(widget.initialAmenities);
    _amenityController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant AmenityInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update state if initial amenities change externally
    if (widget.initialAmenities != oldWidget.initialAmenities) {
      setState(() {
        _selectedAmenities = List.from(widget.initialAmenities);
      });
    }
  }

  @override
  void dispose() {
    _amenityController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addAmenity(String amenity) {
    amenity = amenity.trim();
    if (amenity.isNotEmpty && !_selectedAmenities.contains(amenity)) {
      setState(() {
        _selectedAmenities.add(amenity);
      });
      widget.onChanged(_selectedAmenities);
    }
    _amenityController.clear();
    _focusNode.requestFocus(); // Keep focus after adding
  }

  void _removeAmenity(String amenity) {
    setState(() {
      _selectedAmenities.remove(amenity);
    });
    widget.onChanged(_selectedAmenities);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<String>(
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Add Amenity',
                hintText: 'Type or select an amenity',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    _addAmenity(controller.text);
                  },
                ),
              ),
              onFieldSubmitted: (value) {
                _addAmenity(value);
              },
              onChanged: (_) {
                // Optionally trigger autocomplete suggestions on change
                setState(() {});
              },
            );
          },
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return widget.availableAmenitiesWithIcons.keys.where(
                (a) => !_selectedAmenities.contains(a),
              );
            }
            return widget.availableAmenitiesWithIcons.keys.where((
              String option,
            ) {
              return option.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ) &&
                  !_selectedAmenities.contains(option);
            });
          },
          onSelected: (String selection) {
            _addAmenity(selection);
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 200,
                    maxWidth: 300,
                  ), // Limit width
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      final icon = widget.availableAmenitiesWithIcons[option];
                      return InkWell(
                        onTap: () {
                          onSelected(option);
                        },
                        child: ListTile(
                          leading: icon != null ? Icon(icon) : null,
                          title: Text(option),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        if (_selectedAmenities.isNotEmpty)
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children:
                _selectedAmenities.map((amenity) {
                  final icon = widget.availableAmenitiesWithIcons[amenity];
                  return Chip(
                    avatar: icon != null ? Icon(icon, size: 18) : null,
                    label: Text(amenity),
                    onDeleted: () {
                      _removeAmenity(amenity);
                    },
                  );
                }).toList(),
          )
        else
          Text(
            'No amenities added yet.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
      ],
    );
  }
}
