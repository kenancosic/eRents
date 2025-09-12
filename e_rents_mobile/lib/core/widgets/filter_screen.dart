// import 'package:e_rents_mobile/core/widgets/distribution_slider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_mobile/core/utils/theme.dart';
import 'package:e_rents_mobile/core/widgets/elevated_text_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';

class FilterScreen extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;
  final Function(Map<String, dynamic>) onApplyFilters;

  const FilterScreen({
    super.key,
    this.initialFilters,
    required this.onApplyFilters,
  });

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  // Filter state variables
  String _selectedPropertyType = 'Any';
  RangeValues _priceRange = const RangeValues(1200, 3000);
  String _rentalPeriod = 'Any';
  final List<String> _selectedFacilities = [];

  // City and Sort state
  final TextEditingController _cityController = TextEditingController();
  String _city = '';
  String _priceSort = 'None'; // 'None' | 'LowToHigh' | 'HighToLow'

  // Constants
  final List<String> _propertyTypes = [
    'Any',
    'House',
    'Studio',
    'Cabin',
    'Apartment'
  ];
  final List<String> _rentalPeriods = ['Any', 'Monthly', 'Per day'];
  final List<String> _facilities = [
    'Any',
    'WiFi',
    'Self check-in',
    'Kitchen',
    'Free parking',
    'Air conditioner',
    'Security'
  ];

  // New state variables
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isDateFilterEnabled = false;
  bool _useEndDate = true;
  bool _includePartialDaily = false; // Only meaningful for Per day rentals

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

      // City
      _city = (widget.initialFilters!['city'] ?? widget.initialFilters!['City'] ?? '').toString();
      _cityController.text = _city;

      // Sort by price
      final sortBy = (widget.initialFilters!['sortBy'] ?? widget.initialFilters!['SortBy'])
          ?.toString()
          .toLowerCase();
      final sortDir = (widget.initialFilters!['sortDirection'] ?? widget.initialFilters!['SortDirection'])
          ?.toString()
          .toLowerCase();
      if (sortBy == 'price') {
        if (sortDir == 'asc') {
          _priceSort = 'LowToHigh';
        } else if (sortDir == 'desc') {
          _priceSort = 'HighToLow';
        }
      }

      // Include partial availability (daily only)
      final includePartial = widget.initialFilters!['includePartialDaily'] ?? widget.initialFilters!['partialAvailability'];
      if (includePartial is bool) {
        _includePartialDaily = includePartial;
      }

      // Initialize date filters if provided
      final start = widget.initialFilters!['startDate'];
      final end = widget.initialFilters!['endDate'];
      DateTime? parsedStart;
      DateTime? parsedEnd;
      if (start is String) {
        parsedStart = DateTime.tryParse(start);
      } else if (start is DateTime) {
        parsedStart = start;
      }
      if (end is String) {
        parsedEnd = DateTime.tryParse(end);
      } else if (end is DateTime) {
        parsedEnd = end;
      }

      if (parsedStart != null && parsedEnd != null && parsedEnd.isAfter(parsedStart)) {
        _startDate = parsedStart;
        _endDate = parsedEnd;
        _isDateFilterEnabled = true;
      }
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedPropertyType = 'Any';
      _priceRange = const RangeValues(1200, 3000);
      _rentalPeriod = 'Any';
      _selectedFacilities.clear();
      _selectedFacilities.add('Any');
      // Clear city and sort selections
      _city = '';
      _cityController.text = '';
      _priceSort = 'None';
    });
  }

  void _applyFilters() {
    // Map UI selections to provider/backend-friendly keys
    String? mapPropertyType(String value) {
      switch (value) {
        case 'Apartment':
        case 'House':
        case 'Studio':
          return value; // valid backend enum names
        case 'Cabin':
          // Not a backend enum; skip
          return null;
        case 'Any':
        default:
          return null;
      }
    }

    String? mapRentingType(String value) {
      switch (value) {
        case 'Monthly':
          return 'Monthly';
        case 'Per day':
          return 'Daily';
        default:
          return null; // 'Any' or unknown
      }
    }

    final mapped = <String, dynamic>{
      // Price range maps to min/maxPrice recognized by PropertySearchProvider._translateFilters()
      'minPrice': _priceRange.start.round(),
      'maxPrice': _priceRange.end.round(),
      // Property type maps to backend enum name when applicable
      if (mapPropertyType(_selectedPropertyType) != null)
        'propertyType': mapPropertyType(_selectedPropertyType),
      // Renting type maps to backend enum name
      if (mapRentingType(_rentalPeriod) != null)
        'rentingType': mapRentingType(_rentalPeriod),
      // City override
      if (_city.trim().isNotEmpty) 'city': _city.trim(),
      // Sort by price
      if (_priceSort != 'None') 'sortBy': 'price',
      if (_priceSort == 'LowToHigh') 'sortDirection': 'asc',
      if (_priceSort == 'HighToLow') 'sortDirection': 'desc',
      // Dates are optional and currently not supported server-side for search; include for future use
      if (_isDateFilterEnabled) 'startDate': _startDate.toIso8601String(),
      if (_isDateFilterEnabled && (_useEndDate || _rentalPeriod == 'Per day'))
        'endDate': _endDate.toIso8601String(),
      // Daily rentals: allow partial availability inclusion when date filter is enabled
      if (_isDateFilterEnabled && _rentalPeriod == 'Per day') 'includePartialDaily': _includePartialDaily,
    };
    widget.onApplyFilters(mapped);
    context.pop();
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
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Filters',
          style: theme.textTheme.headlineMedium,
        ),
        actions: [
          ElevatedTextButton.icon(
            text: 'Reset all',
            icon: Icons.refresh,
            isCompact: true,
            onPressed: _resetFilters,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // City Section
              Text(
                'City',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(
                  hintText: 'Enter city (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
                onChanged: (val) => _city = val,
              ),

              const SizedBox(height: 24),

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
                      inactiveColor:
                          Colors.white.withAlpha((255 * 0.3).round()),
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
                child: ElevatedTextButton.icon(
                  text: 'Reset price',
                  icon: Icons.refresh,
                  isCompact: true,
                  onPressed: () {
                    setState(() {
                      _priceRange = const RangeValues(1200, 3000);
                    });
                  },
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

                // Partial availability option (daily only)
                if (_rentalPeriod == 'Per day') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.filter_alt_outlined, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Include properties with partial availability in the selected dates',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Switch(
                        value: _includePartialDaily,
                        onChanged: (val) => setState(() => _includePartialDaily = val),
                        activeColor: primaryColor,
                      ),
                    ],
                  ),
                ],
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
                  ElevatedTextButton(
                    text: 'See more',
                    isCompact: true,
                    onPressed: () {
                      // Show more facilities
                    },
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
                child: CustomButton(
                  label: 'Show results',
                  isLoading: false,
                  width: ButtonWidth.expanded,
                  onPressed: _applyFilters,
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
        ElevatedTextButton.icon(
          text: 'Select date range',
          icon: Icons.date_range,
          isCompact: true,
          onPressed: () => _selectDateRange(context, false),
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
          ElevatedTextButton.icon(
            text: 'Select month range',
            icon: Icons.date_range,
            isCompact: true,
            onPressed: () => _selectDateRange(context, true),
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
              dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
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
      if (!context.mounted) return;
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
        builder: (BuildContext dialogContext) {
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
              ElevatedTextButton(
                text: 'Cancel',
                isCompact: true,
                onPressed: () => dialogContext.pop(),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open month picker: $e')),
      );
    }
  }

  Future<void> _selectYearForMonth(
      BuildContext context, int month, bool isStartDate) async {
    final int currentYear = DateTime.now().year;
    final List<int> years = List.generate(5, (index) => currentYear + index);

    showDialog(
      context: context,
      builder: (BuildContext yearDialogContext) {
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
                    yearDialogContext.pop();
                    if (!context.mounted) return;
                    context.pop();

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
            ElevatedTextButton(
              text: 'Cancel',
              isCompact: true,
              onPressed: () => yearDialogContext.pop(),
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
              dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
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
      if (!context.mounted) return;
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
