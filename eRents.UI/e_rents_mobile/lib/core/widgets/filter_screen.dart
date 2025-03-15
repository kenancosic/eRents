import 'package:e_rents_mobile/core/widgets/distribution_slider.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:e_rents_mobile/core/utils/theme.dart';

class FilterScreen extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;
  final Function(Map<String, dynamic>) onApplyFilters;

  const FilterScreen({
    Key? key,
    this.initialFilters,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  // Filter state variables
  String _selectedPropertyType = 'Any';
  RangeValues _priceRange = const RangeValues(1200, 3000);
  String _rentalPeriod = 'Monthly';
  final List<String> _selectedFacilities = [];

  // Constants
  final List<String> _propertyTypes = [
    'Any',
    'House',
    'Studio',
    'Cabin',
    'Apartment'
  ];
  final List<String> _rentalPeriods = ['Any', 'Monthly', 'Annually', 'Per day'];
  final List<String> _facilities = [
    'Any',
    'WiFi',
    'Self check-in',
    'Kitchen',
    'Free parking',
    'Air conditioner',
    'Security'
  ];

  // In your FilterScreen class, add this sample price distribution data
  // This would ideally come from your backend in a real application
  final List<int> _priceDistributionData = [
    10,
    15,
    25,
    40,
    60,
    80,
    95,
    75,
    50,
    35,
    25,
    20,
    15,
    10,
    8,
    5,
    3,
    2,
    1,
    1
  ]; // Number of properties at each price point

  // New state variables
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isDateFilterEnabled = false;
  bool _useEndDate = true;

  @override
  void initState() {
    super.initState();
    // Initialize with existing filters if provided
    if (widget.initialFilters != null) {
      _selectedPropertyType = widget.initialFilters!['propertyType'] ?? 'Any';
      _priceRange =
          widget.initialFilters!['priceRange'] ?? const RangeValues(1200, 3000);
      _rentalPeriod = widget.initialFilters!['rentalPeriod'] ?? 'Monthly';
      _selectedFacilities.clear();
      _selectedFacilities.addAll(
          List<String>.from(widget.initialFilters!['facilities'] ?? ['Any']));
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedPropertyType = 'Any';
      _priceRange = const RangeValues(1200, 3000);
      _rentalPeriod = 'Monthly';
      _selectedFacilities.clear();
      _selectedFacilities.add('Any');
    });
  }

  void _applyFilters() {
    final filters = {
      'propertyType': _selectedPropertyType,
      'priceRange': _priceRange,
      'rentalPeriod': _rentalPeriod,
      'facilities': _selectedFacilities,
      'dateFilterEnabled': _isDateFilterEnabled,
      'startDate': _isDateFilterEnabled ? _startDate : null,
      'endDate':
          _isDateFilterEnabled && (_useEndDate || _rentalPeriod == 'Per day')
              ? _endDate
              : null,
      'isMonthlyRental':
          _rentalPeriod == 'Monthly' || _rentalPeriod == 'Annually',
      'useEndDate': _useEndDate,
    };
    widget.onApplyFilters(filters);
    Navigator.pop(context);
  }

  void _toggleFacility(String facility) {
    setState(() {
      if (facility == 'Any') {
        _selectedFacilities.clear();
        _selectedFacilities.add('Any');
      } else {
        // Remove 'Any' if it's selected
        _selectedFacilities.remove('Any');

        // Toggle the selected facility
        if (_selectedFacilities.contains(facility)) {
          _selectedFacilities.remove(facility);
          // If no facilities are selected, select 'Any'
          if (_selectedFacilities.isEmpty) {
            _selectedFacilities.add('Any');
          }
        } else {
          _selectedFacilities.add(facility);
        }
      }
    });
  }

  // New methods
  void _handleDateRangeSelected(DateTime start, DateTime end) {
    setState(() {
      _startDate = start;
      _endDate = end;
      _isDateFilterEnabled = true;
    });
  }

  void _handleInvalidDateSelection(DateTime start, DateTime end) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selected dates include unavailable days.')),
    );
  }

  void _toggleDateFilter(bool value) {
    setState(() {
      _isDateFilterEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Filters',
          style: theme.textTheme.headlineMedium,
        ),
        actions: [
          TextButton.icon(
            onPressed: _resetFilters,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reset all'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Type Section
              Text(
                'Property type',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _buildChipSelection(
                _propertyTypes,
                _selectedPropertyType,
                (value) => setState(() => _selectedPropertyType = value),
                singleSelection: true,
              ),

              const SizedBox(height: 24),

              // Price Range Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Price range',
                    style: theme.textTheme.headlineSmall,
                  ),
                  Text(
                    '\$${_priceRange.start.toInt()} - \$${_priceRange.end.toInt()}+ / month',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // More compact price range slider with app theme colors
              Container(
                height: 40,
                decoration: AppDecorations.gradientBox(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: SliderTheme(
                    data: SliderThemeData(
                      rangeThumbShape: const RoundRangeSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                      trackHeight: 4,
                    ),
                    child: RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 5000,
                      divisions: 50,
                      activeColor: Colors.white,
                      inactiveColor: Colors.white.withOpacity(0.3),
                      labels: RangeLabels(
                        '\$${_priceRange.start.toInt()}',
                        '\$${_priceRange.end.toInt()}+',
                      ),
                      onChanged: (values) {
                        setState(() {
                          _priceRange = values;
                        });
                      },
                    ),
                  ),
                ),
              ),

              // Price tick marks
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('\$0', style: theme.textTheme.bodySmall),
                    Text('\$2500', style: theme.textTheme.bodySmall),
                    Text('\$5000+', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),

              // Add reset price range button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _priceRange = const RangeValues(1200, 3000);
                    });
                  },
                  icon: const Icon(Icons.refresh, size: 14),
                  label:
                      const Text('Reset price', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Rental Period Section
              Text(
                'Rental period',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _buildChipSelection(
                _rentalPeriods,
                _rentalPeriod,
                (value) => setState(() => _rentalPeriod = value),
                singleSelection: true,
              ),

              const SizedBox(height: 24),

              // Date Availability Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date availability',
                    style: theme.textTheme.headlineSmall,
                  ),
                  Switch(
                    value: _isDateFilterEnabled,
                    onChanged: _toggleDateFilter,
                    activeColor: primaryColor,
                    inactiveThumbColor: Colors.grey[300],
                    inactiveTrackColor: Colors.grey[200],
                  ),
                ],
              ),

              if (_isDateFilterEnabled) ...[
                const SizedBox(height: 12),

                // Date selection based on rental period
                _rentalPeriod == 'Per day'
                    ? _buildDailyDatePicker()
                    : _buildMonthlyDatePicker(),
              ],

              const SizedBox(height: 24),

              // Property Facilities Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Property facilities',
                    style: theme.textTheme.headlineSmall,
                  ),
                  TextButton(
                    onPressed: () {
                      // Show more facilities
                    },
                    child: const Text('See more'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Facilities chips (multi-select)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _facilities.map((facility) {
                  final isSelected = _selectedFacilities.contains(facility);
                  return ChoiceChip(
                    label: Text(facility),
                    selected: isSelected,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                    onSelected: (selected) => _toggleFacility(facility),
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              // Apply Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('Show results'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChipSelection(
      List<String> options, String selectedOption, Function(String) onSelected,
      {bool singleSelection = false}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option == selectedOption;
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              onSelected(option);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildDailyDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectSingleDate(context, true),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: AppDecorations.roundedBox(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Check-in',
                          style: TextStyle(
                              color: textSecondaryColor, fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Icon(Icons.arrow_drop_down, color: primaryColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _selectSingleDate(context, false),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: AppDecorations.roundedBox(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Check-out',
                          style: TextStyle(
                              color: textSecondaryColor, fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Icon(Icons.arrow_drop_down, color: primaryColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => _selectDateRange(context, false),
          icon: Icon(Icons.date_range, color: primaryColor),
          label: const Text('Select date range'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyDatePicker() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle for single month vs range
        Row(
          children: [
            Text('Month range', style: TextStyle(color: textSecondaryColor)),
            const Spacer(),
            Switch(
              value: _useEndDate,
              onChanged: (value) {
                setState(() {
                  _useEndDate = value;
                });
              },
              activeColor: primaryColor,
              inactiveThumbColor: Colors.grey[300],
              inactiveTrackColor: Colors.grey[200],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Start month selector
        Container(
          padding: const EdgeInsets.all(12),
          decoration: AppDecorations.roundedBox(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_useEndDate ? 'Start month' : 'Month',
                  style: TextStyle(color: textSecondaryColor, fontSize: 12)),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _selectSingleMonth(context, true),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      '${months[_startDate.month - 1]} ${_startDate.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: primaryColor),
                  ],
                ),
              ),
            ],
          ),
        ),

        // End month selector (only if using range)
        if (_useEndDate) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: AppDecorations.roundedBox(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('End month',
                    style: TextStyle(color: textSecondaryColor, fontSize: 12)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => _selectSingleMonth(context, false),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        '${months[_endDate.month - 1]} ${_endDate.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: primaryColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Range selector button (only if using range)
        if (_useEndDate) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _selectDateRange(context, true),
            icon: Icon(Icons.date_range, color: primaryColor),
            label: const Text('Select month range'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ],
    );
  }

  // Method to show date picker based on rental type
  Future<void> _selectDateRange(BuildContext context, bool isMonthly) async {
    if (isMonthly) {
      // For monthly selection, show month range picker
      _selectMonthRange(context);
      return;
    }

    try {
      // Original date range picker for daily selection
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        saveText: 'Apply',
        confirmText: 'Apply',
        cancelText: 'Cancel',
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: primaryColor,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        setState(() {
          _startDate = picked.start;
          _endDate = picked.end;
          _isDateFilterEnabled = true;
        });
      }
    } catch (e) {
      print('Error showing date picker: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open date picker: $e')),
      );
    }
  }

  void _selectMonthRange(BuildContext context) {
    // First select start month
    _selectSingleMonth(context, true).then((_) {
      // Then select end month if using range
      if (_useEndDate) {
        _selectSingleMonth(context, false);
      }
    });
  }

  Future<void> _selectSingleMonth(
      BuildContext context, bool isStartDate) async {
    try {
      final DateTime initialDate = isStartDate ? _startDate : _endDate;

      // Show month picker instead of date picker
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title:
                Text(isStartDate ? 'Select Start Month' : 'Select End Month'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.5,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final months = [
                    'Jan',
                    'Feb',
                    'Mar',
                    'Apr',
                    'May',
                    'Jun',
                    'Jul',
                    'Aug',
                    'Sep',
                    'Oct',
                    'Nov',
                    'Dec'
                  ];
                  return InkWell(
                    onTap: () {
                      // When month is selected, show year picker
                      _selectYearForMonth(context, index + 1, isStartDate);
                    },
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: initialDate.month == index + 1
                            ? primaryColor
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          months[index],
                          style: TextStyle(
                            color: initialDate.month == index + 1
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error showing month picker: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open month picker: $e')),
      );
    }
  }

  // Add this new method to handle year selection after month is selected
  Future<void> _selectYearForMonth(
      BuildContext context, int month, bool isStartDate) async {
    final int currentYear = DateTime.now().year;
    final List<int> years = List.generate(5, (index) => currentYear + index);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Year for ${[
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December'
          ][month - 1]}'),
          content: SizedBox(
            width: double.maxFinite,
            height: 200,
            child: ListView.builder(
              itemCount: years.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Center(child: Text(years[index].toString())),
                  tileColor: years[index] == DateTime.now().year
                      ? Colors.grey[200]
                      : null,
                  onTap: () {
                    Navigator.pop(context); // Close year dialog
                    Navigator.pop(context); // Close month dialog

                    setState(() {
                      if (isStartDate) {
                        // Set to first day of selected month
                        _startDate = DateTime(years[index], month, 1);

                        // If end date is before start date, update it
                        if (_useEndDate && _endDate.isBefore(_startDate)) {
                          // Set to last day of the same month
                          final lastDay =
                              DateTime(_startDate.year, _startDate.month + 1, 0)
                                  .day;
                          _endDate = DateTime(
                              _startDate.year, _startDate.month, lastDay);
                        }
                      } else {
                        // Set to last day of selected month
                        final lastDay =
                            DateTime(years[index], month + 1, 0).day;
                        _endDate = DateTime(years[index], month, lastDay);

                        // If end date is before start date, update start date
                        if (_endDate.isBefore(_startDate)) {
                          _startDate =
                              DateTime(_endDate.year, _endDate.month, 1);
                        }
                      }
                      _isDateFilterEnabled = true;
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectSingleDate(BuildContext context, bool isStartDate) async {
    try {
      final DateTime initialDate = isStartDate ? _startDate : _endDate;
      final DateTime minDate = isStartDate
          ? DateTime.now()
          : _startDate.add(const Duration(days: 1));

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: minDate,
        lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: primaryColor,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        setState(() {
          if (isStartDate) {
            _startDate = picked;
            // If end date is before or equal to start date, update it
            if (_endDate.isBefore(_startDate) ||
                _endDate.isAtSameMomentAs(_startDate)) {
              _endDate = _startDate.add(const Duration(days: 1));
            }
          } else {
            _endDate = picked;
          }
          _isDateFilterEnabled = true;
        });
      }
    } catch (e) {
      print('Error showing date picker: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open date picker: $e')),
      );
    }
  }
}

// Custom clipper for the wave shape in the price slider
class DynamicWaveShapeClipper extends CustomClipper<Path> {
  final List<double> distribution;

  DynamicWaveShapeClipper(this.distribution);

  @override
  Path getClip(Size size) {
    final path = Path();

    // Start at bottom-left
    path.moveTo(0, size.height);

    // Draw line to top-left with slight curve
    path.lineTo(0, size.height * 0.5);

    // Calculate points based on distribution
    final segmentWidth = size.width / (distribution.length - 1);

    for (int i = 0; i < distribution.length; i++) {
      final x = i * segmentWidth;
      final normalizedHeight = distribution[i]; // Should be between 0 and 1
      final y =
          size.height * (0.5 - normalizedHeight * 0.4); // Scale appropriately

      if (i == 0) {
        path.lineTo(x, y);
      } else {
        // Use quadratic bezier for smoother curve
        final prevX = (i - 1) * segmentWidth;
        final controlX = (prevX + x) / 2;
        path.quadraticBezierTo(controlX, path.getBounds().top, x, y);
      }
    }

    // Line to bottom-right
    path.lineTo(size.width, size.height);

    // Close the path
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
