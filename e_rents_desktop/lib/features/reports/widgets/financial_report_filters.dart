import 'package:flutter/material.dart';
import 'package:e_rents_desktop/features/reports/models/financial_report_models.dart';
import 'package:e_rents_desktop/widgets/custom_button.dart';

class FinancialReportFilters extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final FinancialReportGroupBy groupBy;
  final FinancialReportSortBy sortBy;
  final bool sortDescending;
  final RentalType? selectedRentalType;
  final Function(DateTime, DateTime) onDateRangeChanged;
  final Function(FinancialReportGroupBy) onGroupByChanged;
  final Function(FinancialReportSortBy, bool) onSortingChanged;
  final Function(RentalType?) onRentalTypeChanged;
  final Future<void> Function()? onClearFilters;
  final Future<void> Function() onExportToPdf;
  final bool isExporting;

  const FinancialReportFilters({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.groupBy,
    required this.sortBy,
    required this.sortDescending,
    this.selectedRentalType,
    required this.onDateRangeChanged,
    required this.onGroupByChanged,
    required this.onSortingChanged,
    required this.onRentalTypeChanged,
    required this.onClearFilters,
    required this.onExportToPdf,
    this.isExporting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: const Text(
          'Financial Report Filters',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: const Icon(Icons.filter_list),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildDateField(context, 'Start Date', startDate,
                          (date) => onDateRangeChanged(date, endDate)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _buildDateField(context, 'End Date', endDate,
                          (date) => onDateRangeChanged(startDate, date)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: _buildDropdown(
                        context,
                        'Group By',
                        groupBy,
                        FinancialReportGroupBy.values,
                        (group) => group.displayName,
                        (value) {
                          if (value != null) onGroupByChanged(value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildSortBy(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _buildDropdown<RentalType?>(
                        context,
                        'Rental Type',
                        selectedRentalType,
                        [null, ...RentalType.values],
                        (type) => type?.displayName ?? 'All Types',
                        onRentalTypeChanged,
                      ),
                    ),
                    const Spacer(flex: 2),
                    TextButton.icon(
                      onPressed: onClearFilters,
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 110,
                      child: CustomButton(
                        label: 'Export',
                        icon: Icons.download_for_offline_outlined,
                        isLoading: isExporting,
                        onPressed: onExportToPdf,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSortBy(BuildContext context) {
    return _buildDropdown<FinancialReportSortBy>(
      context,
      'Sort By',
      sortBy,
      FinancialReportSortBy.values,
      (sort) => sort.displayName,
      (value) {
        if (value != null) onSortingChanged(value, sortDescending);
      },
      suffixIcon: IconButton(
        onPressed: () => onSortingChanged(sortBy, !sortDescending),
        icon: Icon(
          sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
          color: Theme.of(context).primaryColor,
          size: 20,
        ),
        tooltip: sortDescending ? 'Descending' : 'Ascending',
      ),
    );
  }

  Widget _buildDropdown<T>(
    BuildContext context,
    String label,
    T value,
    List<T> items,
    String Function(T) displayText,
    void Function(T?)? onChanged,
    {Widget? suffixIcon}
  ) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        suffixIcon: suffixIcon,
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(displayText(item)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    DateTime date,
    Function(DateTime) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (selectedDate != null) {
          onChanged(selectedDate);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const Icon(Icons.calendar_today, size: 16),
          ],
        ),
      ),
    );
  }

}
