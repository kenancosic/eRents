# eRents Desktop Application Reports Feature Documentation

## Overview

This document provides detailed documentation for the reports feature in the eRents desktop application. This feature allows property managers to generate, view, and export various reports related to properties, tenants, bookings, payments, and maintenance.

## Feature Structure

The reports feature is organized in the `lib/features/reports/` directory with the following structure:

```
lib/features/reports/
├── providers/
│   └── reports_provider.dart
├── screens/
│   ├── reports_list_screen.dart
│   ├── report_detail_screen.dart
│   └── report_generator_screen.dart
├── widgets/
│   ├── report_filters.dart
│   ├── report_preview.dart
│   └── export_options.dart
└── models/
    ├── report_template.dart
    ├── report_data.dart
    └── export_format.dart
```

## Core Components

### Report Template Model

The `ReportTemplate` model represents a predefined report template with the following key properties:

- `id`: Unique identifier
- `name`: Report name
- `description`: Report description
- `category`: Report category (financial, property, tenant, maintenance)
- `parameters`: Required parameters for the report
- `defaultFormat`: Default export format
- `createdAt`: Creation timestamp
- `updatedAt`: Last update timestamp

### Report Data Model

The `ReportData` model represents the data for a generated report:

- `templateId`: Associated template ID
- `parameters`: Actual parameter values used
- `generatedAt`: Generation timestamp
- `data`: Report data content
- `summary`: Report summary statistics
- `charts`: Chart data for visualization

### Reports Provider

The `ReportsProvider` extends `BaseProvider` and manages reports data with caching and state management:

#### Properties

- `reportTemplates`: Available report templates
- `generatedReports`: Recently generated reports
- `selectedReport`: Currently selected report
- `reportFilters`: Current filter criteria
- `isGenerating`: Whether a report is being generated

#### Methods

- `loadReportTemplates()`: Load available report templates
- `generateReport(ReportTemplate template, Map<String, dynamic> parameters)`: Generate a report
- `loadGeneratedReport(int reportId)`: Load a previously generated report
- `exportReport(int reportId, ExportFormat format)`: Export a report in specified format
- `deleteGeneratedReport(int reportId)`: Delete a generated report
- `applyFilters(Map<String, dynamic> filters)`: Apply filter criteria

## Screens

### Reports List Screen

Displays a list of available report templates and recently generated reports.

#### Features

- Report template categories
- Recently generated reports list
- Report generation quick actions
- Filter and search capabilities
- Loading and error states

#### Implementation

```dart
// ReportsListScreen widget
@override
Widget build(BuildContext context) {
  return Consumer<ReportsProvider>(
    builder: (context, provider, child) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Reports'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: provider.loadReportTemplates,
            ),
          ],
        ),
        body: ContentWrapper(
          child: Column(
            children: [
              _buildReportCategories(),
              Expanded(
                child: ListView(
                  children: [
                    _buildTemplateSection(),
                    _buildGeneratedReportsSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
```

### Report Generator Screen

Provides a form for selecting report parameters and generating reports.

#### Features

- Parameter selection based on template
- Date range selection
- Filter options
- Preview capability
- Generate and export actions

#### Implementation

```dart
// ReportGeneratorScreen widget
@override
Widget build(BuildContext context) {
  return Consumer<ReportsProvider>(
    builder: (context, provider, child) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.template.name),
        ),
        body: ContentWrapper(
          child: Column(
            children: [
              _buildParameterForm(),
              _buildPreviewSection(),
              _buildActionButtons(),
            ],
          ),
        ),
      );
    },
  );
}
```

### Report Detail Screen

Displays detailed report data with charts, tables, and export options.

#### Features

- Report data visualization
- Interactive charts
- Data tables
- Export options
- Summary statistics

#### Implementation

```dart
// ReportDetailScreen widget
@override
Widget build(BuildContext context) {
  return Consumer<ReportsProvider>(
    builder: (context, provider, child) {
      return Scaffold(
        appBar: AppBar(
          title: Text(provider.selectedReport?.template.name ?? 'Report'),
          actions: [
            IconButton(
              icon: Icon(Icons.download),
              onPressed: _showExportOptions,
            ),
          ],
        ),
        body: ContentWrapper(
          child: provider.isLoading && provider.selectedReport == null
              ? Center(child: CircularProgressIndicator())
              : provider.error != null
                  ? ErrorDisplay(error: provider.error)
                  : _buildReportContent(),
        ),
      );
    },
  );
}
```

## Widgets

### Report Filters

Custom widget for selecting report parameters and filters.

### Report Preview

Widget for previewing report data before generation.

### Export Options

Widget for selecting export format and options.

## Integration with Base Provider Architecture

The reports feature fully leverages the base provider architecture:

```dart
// ReportsProvider using base provider features
class ReportsProvider extends BaseProvider<ReportsProvider> {
  final ApiService _apiService;
  List<ReportTemplate>? _reportTemplates;
  ReportData? _selectedReport;
  bool _isGenerating = false;
  
  ReportsProvider(this._apiService);
  
  List<ReportTemplate>? get reportTemplates => _reportTemplates;
  ReportData? get selectedReport => _selectedReport;
  bool get isGenerating => _isGenerating;
  
  // Cached report templates with moderate TTL
  Future<void> loadReportTemplates() async {
    _reportTemplates = await executeWithCache(
      'report_templates',
      () => executeWithState(() async {
        return await _apiService.getListAndDecode<ReportTemplate>(
          '/api/reports/templates',
          ReportTemplate.fromJson,
        );
      }),
      ttl: const Duration(minutes: 30), // Moderate TTL for templates
    );
    notifyListeners();
  }
  
  // Generate report without caching (unique each time)
  Future<ReportData?> generateReport(
    ReportTemplate template, 
    Map<String, dynamic> parameters,
  ) async {
    _isGenerating = true;
    notifyListeners();
    
    final reportData = await executeWithState(() async {
      return await _apiService.postAndDecode<ReportData>(
        '/api/reports/generate',
        {
          'templateId': template.id,
          'parameters': parameters,
        },
        ReportData.fromJson,
      );
    });
    
    _isGenerating = false;
    _selectedReport = reportData;
    notifyListeners();
    
    return reportData;
  }
  
  // Load previously generated report
  Future<void> loadGeneratedReport(int reportId) async {
    // Try cache first for recently viewed reports
    final cached = getCachedItem<ReportData>('report_$reportId');
    if (cached != null) {
      _selectedReport = cached;
      notifyListeners();
      return;
    }
    
    // Load from API if not cached
    _selectedReport = await executeWithState(() async {
      return await _apiService.getAndDecode<ReportData>(
        '/api/reports/$reportId',
        ReportData.fromJson,
      );
    });
    
    // Cache the loaded report
    if (_selectedReport != null) {
      cacheItem('report_$reportId', _selectedReport!, ttl: const Duration(minutes: 15));
    }
    
    notifyListeners();
  }
  
  // Export report
  Future<bool> exportReport(int reportId, ExportFormat format) async {
    return await executeWithStateForSuccess(() async {
      await _apiService.download(
        '/api/reports/$reportId/export',
        {
          'format': format.name,
        },
        filename: 'report_$reportId.${format.extension}',
      );
    });
  }
  
  // Delete generated report
  Future<bool> deleteGeneratedReport(int reportId) async {
    final success = await executeWithStateForSuccess(() async {
      await _apiService.delete('/api/reports/$reportId');
      // Invalidate relevant cache
      invalidateCache('report_$reportId');
    });
    
    if (success) {
      // Clear selected report if it's the one being deleted
      if (_selectedReport?.id == reportId) {
        _selectedReport = null;
      }
    }
    
    notifyListeners();
    return success;
  }
}
```

## Report Categories and Templates

### Financial Reports

- Revenue summary
- Expense tracking
- Profit and loss statement
- Payment history
- Outstanding balances

### Property Reports

- Occupancy rates
- Property performance
- Maintenance costs
- Amenity usage
- Property value trends

### Tenant Reports

- Tenant demographics
- Lease expiration
- Payment history
- Tenant satisfaction
- Move-in/move-out trends

### Maintenance Reports

- Maintenance costs
- Issue resolution times
- Technician performance
- Preventive maintenance
- Emergency response times

## Export Formats

The reports feature supports multiple export formats:

- PDF: Professional printable reports
- Excel: Data analysis and manipulation
- CSV: Simple data export
- JSON: Developer-friendly format
- HTML: Web-friendly format

## Best Practices

1. **Use Appropriate Caching**: Cache templates longer, reports shorter
2. **Handle Loading States**: Show progress during report generation
3. **Error Handling**: Use AppError for structured error handling
4. **Parameter Validation**: Validate report parameters before generation
5. **Memory Management**: Clean up large report data when not needed
6. **Export Options**: Provide multiple export formats
7. **Preview Capability**: Allow preview before generation
8. **Performance Optimization**: Use pagination for large datasets

## Testing

When testing the reports feature:

```dart
// Test reports provider
void main() {
  late ReportsProvider provider;
  late MockApiService mockApiService;
  
  setUp(() {
    mockApiService = MockApiService();
    provider = ReportsProvider(mockApiService);
  });
  
  test('loadReportTemplates uses caching', () async {
    final templates = [
      ReportTemplate(id: 1, name: 'Revenue Summary', category: 'financial'),
      ReportTemplate(id: 2, name: 'Occupancy Rate', category: 'property'),
    ];
    
    when(() => mockApiService.getListAndDecode<ReportTemplate>(
      any(),
      any(),
    )).thenAnswer((_) async => templates);
    
    // First call should hit the API
    await provider.loadReportTemplates();
    verify(() => mockApiService.getListAndDecode<ReportTemplate>(
      '/api/reports/templates',
      any(),
    )).called(1);
    
    // Second call should use cache
    await provider.loadReportTemplates();
    // API should still only be called once
    verify(() => mockApiService.getListAndDecode<ReportTemplate>(
      '/api/reports/templates',
      any(),
    )).called(1);
    
    expect(provider.reportTemplates, equals(templates));
  });
  
  test('generateReport does not use cache', () async {
    final template = ReportTemplate(id: 1, name: 'Test Report', category: 'financial');
    final parameters = {'startDate': '2023-01-01', 'endDate': '2023-12-31'};
    final reportData = ReportData(templateId: 1, parameters: parameters);
    
    when(() => mockApiService.postAndDecode<ReportData>(
      any(),
      any(),
      any(),
    )).thenAnswer((_) async => reportData);
    
    // Generate report
    await provider.generateReport(template, parameters);
    
    // Should always hit API (no caching for generated reports)
    verify(() => mockApiService.postAndDecode<ReportData>(
      '/api/reports/generate',
      any(),
      any(),
    )).called(1);
    
    expect(provider.selectedReport, equals(reportData));
  });
}
```

This documentation ensures consistent implementation of the reports feature and provides a solid foundation for future development.
