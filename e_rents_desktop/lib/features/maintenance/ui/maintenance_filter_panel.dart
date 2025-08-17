import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/crud/list_screen.dart' show FilterController;
import 'package:e_rents_desktop/models/enums/maintenance_issue_priority.dart';
import 'package:e_rents_desktop/models/enums/maintenance_issue_status.dart';
import 'package:e_rents_desktop/presentation/chips.dart';
import 'package:e_rents_desktop/presentation/extensions.dart';

/// Filter panel for Maintenance screens, aligned with Properties filter UX
/// Minimal, business-focused fields mapped to backend MaintenanceIssueSearch:
/// - propertyId (int)
/// - priorityMin/priorityMax (enum range)
/// - statuses[] (multi-select)
/// - createdFrom/createdTo (date range)
class MaintenanceFilterPanel extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;
  final bool showSearchField;
  final FilterController? controller;

  const MaintenanceFilterPanel({
    super.key,
    this.initialFilters,
    this.showSearchField = true,
    this.controller,
  });

  @override
  State<MaintenanceFilterPanel> createState() => _MaintenanceFilterPanelState();
}

class _MaintenanceFilterPanelState extends State<MaintenanceFilterPanel> {
  final _propertyIdController = TextEditingController();
  MaintenanceIssuePriority? _priorityMin;
  MaintenanceIssuePriority? _priorityMax;
  final Set<MaintenanceIssueStatus> _statuses = <MaintenanceIssueStatus>{};
  DateTime? _createdFrom;
  DateTime? _createdTo;
  final _searchController = TextEditingController();
  

  @override
  void initState() {
    super.initState();
    final init = widget.initialFilters ?? const <String, dynamic>{};
    if (init.isNotEmpty) {
      final pid = init['propertyId'] as int?;
      if (pid != null) _propertyIdController.text = pid.toString();
      _priorityMin = _parsePriority(init['priorityMin']);
      _priorityMax = _parsePriority(init['priorityMax']);
      final List statuses = (init['statuses'] as List?) ?? const [];
      for (final s in statuses) {
        final parsed = _parseStatus(s);
        if (parsed != null) _statuses.add(parsed);
      }
      _createdFrom = _parseDate(init['createdFrom']);
      _createdTo = _parseDate(init['createdTo']);
      
    }

    widget.controller?.bind(
      getFilters: _buildFilters,
      resetFields: _reset,
    );
  }

  @override
  void dispose() {
    _propertyIdController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildFilters() {
    final map = <String, dynamic>{
      'propertyId': int.tryParse(_propertyIdController.text),
      'priorityMin': _priorityMin?.name,
      'priorityMax': _priorityMax?.name,
      'statuses': _statuses.map((e) => e.name).toList(),
      'createdFrom': _createdFrom?.toIso8601String(),
      'createdTo': _createdTo?.toIso8601String(),
    }..removeWhere((k, v) => v == null || (v is List && v.isEmpty));

    return map;
  }

  void _reset() {
    setState(() {
      _propertyIdController.clear();
      _priorityMin = null;
      _priorityMax = null;
      _statuses.clear();
      _createdFrom = null;
      _createdTo = null;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            _buildPropertyId(),
            _buildPriorityRange(),
            _buildStatusChips(),
            _buildDateRange(context),
          ],
        ),
      ),
    );
  }

  

  Widget _buildPropertyId() {
    return TextFormField(
      controller: _propertyIdController,
      decoration: const InputDecoration(
        labelText: 'Property ID',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.home_outlined),
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildPriorityRange() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<MaintenanceIssuePriority?>(
            value: _priorityMin,
            decoration: const InputDecoration(
              labelText: 'Min Priority',
              border: OutlineInputBorder(),
            ),
            items: [null, ...MaintenanceIssuePriority.values]
                .map((p) => DropdownMenuItem<MaintenanceIssuePriority?>(
                      value: p,
                      child: Text(p?.displayName ?? 'Any'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _priorityMin = v),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<MaintenanceIssuePriority?>(
            value: _priorityMax,
            decoration: const InputDecoration(
              labelText: 'Max Priority',
              border: OutlineInputBorder(),
            ),
            items: [null, ...MaintenanceIssuePriority.values]
                .map((p) => DropdownMenuItem<MaintenanceIssuePriority?>(
                      value: p,
                      child: Text(p?.displayName ?? 'Any'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _priorityMax = v),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Statuses', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        EnumFilterChips<MaintenanceIssueStatus>(
          values: MaintenanceIssueStatus.values,
          selected: _statuses,
          labelBuilder: (s) => s.displayName,
          colorBuilder: (s) => s.color,
          onChanged: (next) => setState(() => _statuses
            ..clear()
            ..addAll(next)),
        ),
      ],
    );
  }

  Widget _buildDateRange(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _createdFrom ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _createdFrom = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Created From',
                border: OutlineInputBorder(),
              ),
              child: Text(_createdFrom == null
                  ? 'Any'
                  : MaterialLocalizations.of(context).formatMediumDate(_createdFrom!)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _createdTo ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _createdTo = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Created To',
                border: OutlineInputBorder(),
              ),
              child: Text(_createdTo == null
                  ? 'Any'
                  : MaterialLocalizations.of(context).formatMediumDate(_createdTo!)),
            ),
          ),
        ),
      ],
    );
  }

  MaintenanceIssuePriority? _parsePriority(dynamic v) {
    if (v == null) return null;
    try {
      final name = v.toString();
      return MaintenanceIssuePriority.values.firstWhere(
        (e) => e.name == name,
        orElse: () => MaintenanceIssuePriority.values.first,
      );
    } catch (_) {
      return null;
    }
  }

  MaintenanceIssueStatus? _parseStatus(dynamic v) {
    if (v == null) return null;
    try {
      final name = v.toString();
      return MaintenanceIssueStatus.values.firstWhere(
        (e) => e.name == name,
        orElse: () => MaintenanceIssueStatus.values.first,
      );
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }
}
