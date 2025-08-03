# eRents Desktop Application Dashboard Feature Documentation

## Overview

This document provides detailed documentation for the dashboard feature in the eRents desktop application. This feature provides property managers with an overview of key metrics, recent activities, and quick access to important functions.

## Feature Structure

The dashboard feature is organized in the `lib/features/dashboard/` directory with the following structure:

```
lib/features/dashboard/
├── providers/
│   └── dashboard_provider.dart
├── screens/
│   └── dashboard_screen.dart
├── widgets/
│   ├── metrics_summary.dart
│   ├── recent_activities.dart
│   ├── quick_actions.dart
│   └── charts/
│       ├── occupancy_chart.dart
│       ├── revenue_chart.dart
│       └── maintenance_chart.dart
└── models/
    └── dashboard_data.dart
```

## Core Components

### Dashboard Data Model

The `DashboardData` model represents the aggregated data displayed on the dashboard with the following key properties:

- `totalProperties`: Total number of properties
- `occupiedProperties`: Number of occupied properties
- `totalTenants`: Total number of tenants
- `upcomingBookings`: Number of upcoming bookings
- `pendingMaintenance`: Number of pending maintenance issues
- `monthlyRevenue`: Monthly revenue amount
- `occupancyRate`: Current occupancy rate percentage
- `recentActivities`: List of recent activities
- `revenueTrend`: Revenue trend data for charts
- `maintenanceStats`: Maintenance issue statistics

### Dashboard Provider

The `DashboardProvider` extends `BaseProvider` and manages dashboard data with caching and state management:

#### Properties

- `dashboardData`: Current dashboard data
- `isLoading`: Whether data is being loaded
- `error`: Current error state

#### Methods

- `loadDashboardData()`: Load dashboard data with caching
- `refreshDashboardData()`: Force refresh dashboard data
- `getQuickStats()`: Get quick statistics summary
- `getRecentActivities()`: Get recent activities

## Screens

### Dashboard Screen

The main dashboard screen that displays key metrics, charts, and quick actions.

#### Features

- Metrics summary cards
- Interactive charts
- Recent activities list
- Quick action buttons
- Loading and error states
- Auto-refresh capability

#### Implementation

```dart
// DashboardScreen widget
@override
Widget build(BuildContext context) {
  return Consumer<DashboardProvider>(
    builder: (context, provider, child) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Dashboard'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: provider.refreshDashboardData,
            ),
          ],
        ),
        body: ContentWrapper(
          child: provider.isLoading && provider.dashboardData == null
              ? Center(child: CircularProgressIndicator())
              : provider.error != null
                  ? ErrorDisplay(error: provider.error)
                  : RefreshIndicator(
                      onRefresh: provider.refreshDashboardData,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            MetricsSummary(data: provider.dashboardData!),
                            SizedBox(height: 20),
                            ChartsSection(data: provider.dashboardData!),
                            SizedBox(height: 20),
                            RecentActivities(activities: provider.dashboardData!.recentActivities),
                            SizedBox(height: 20),
                            QuickActions(),
                          ],
                        ),
                      ),
                    ),
        ),
      );
    },
  );
}
```

## Widgets

### Metrics Summary

Displays key metrics in card format with visual indicators.

### Recent Activities

Shows a timeline of recent activities with timestamps and details.

### Quick Actions

Provides quick access buttons to common functions.

### Charts Section

Contains various charts for visual data representation:

#### Occupancy Chart

Visualizes property occupancy rates over time.

#### Revenue Chart

Shows revenue trends and comparisons.

#### Maintenance Chart

Displays maintenance issue statistics and trends.

## Integration with Base Provider Architecture

The dashboard feature fully leverages the base provider architecture:

```dart
// DashboardProvider using base provider features
class DashboardProvider extends BaseProvider<DashboardProvider> {
  final ApiService _apiService;
  DashboardData? _dashboardData;
  
  DashboardProvider(this._apiService);
  
  DashboardData? get dashboardData => _dashboardData;
  
  Future<void> loadDashboardData() async {
    _dashboardData = await executeWithState(() async {
      return await _apiService.getAndDecode<DashboardData>(
        '/api/dashboard',
        DashboardData.fromJson,
      );
    });
    notifyListeners();
  }
  
  // Refresh dashboard data
  Future<void> refreshDashboardData() async {
    await loadDashboardData();
  }
  
  // Get quick stats for summary cards
  DashboardStats getQuickStats() {
    if (_dashboardData == null) {
      return DashboardStats.empty();
    }
    
    return DashboardStats(
      totalProperties: _dashboardData!.totalProperties,
      occupiedProperties: _dashboardData!.occupiedProperties,
      occupancyRate: _dashboardData!.occupancyRate,
      totalTenants: _dashboardData!.totalTenants,
      upcomingBookings: _dashboardData!.upcomingBookings,
      pendingMaintenance: _dashboardData!.pendingMaintenance,
      monthlyRevenue: _dashboardData!.monthlyRevenue,
    );
  }
  
  // Get recent activities
  List<Activity> getRecentActivities() {
    return _dashboardData?.recentActivities ?? [];
  }
}
```

## Chart Implementation

The dashboard uses custom chart widgets for data visualization:

```dart
// OccupancyChart widget
class OccupancyChart extends StatelessWidget {
  final DashboardData data;
  
  const OccupancyChart({Key? key, required this.data}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Occupancy Rate',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            // Chart implementation using preferred charting library
            _buildOccupancyChart(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOccupancyChart() {
    // Implementation using charting library
    // This could use charts_flutter, fl_chart, or similar
    return Container(
      height: 200,
      child: // Chart widget implementation
    );
  }
}
```

## Best Practices

1. **Use Appropriate Caching**: Dashboard data can have longer TTL since it's aggregate data
2. **Handle Loading States**: Show loading indicators during initial load
3. **Error Handling**: Use AppError for structured error handling
4. **Responsive Design**: Ensure charts and metrics adapt to different screen sizes
5. **Performance Optimization**: Avoid unnecessary rebuilds of chart components
6. **Data Freshness**: Implement auto-refresh or manual refresh options
7. **Accessibility**: Ensure charts are accessible with proper labels
8. **Visual Consistency**: Maintain consistent styling with the overall theme

## Testing

When testing the dashboard feature:

```dart
// Test dashboard provider
void main() {
  late DashboardProvider provider;
  late MockApiService mockApiService;
  
  setUp(() {
    mockApiService = MockApiService();
    provider = DashboardProvider(mockApiService);
  });
  
  test('loadDashboardData uses caching', () async {
    final dashboardData = DashboardData(
      totalProperties: 10,
      occupiedProperties: 8,
      occupancyRate: 80.0,
      totalTenants: 15,
      upcomingBookings: 3,
      pendingMaintenance: 2,
      monthlyRevenue: 15000,
      recentActivities: [],
      revenueTrend: [],
      maintenanceStats: [],
    );
    
    when(() => mockApiService.getAndDecode<DashboardData>(
      any(),
      any(),
    )).thenAnswer((_) async => dashboardData);
    
    // First call should hit the API
    await provider.loadDashboardData();
    verify(() => mockApiService.getAndDecode<DashboardData>(
      '/api/dashboard',
      any(),
    )).called(1);
    
    // Second call will make a new API request
    await provider.loadDashboardData();
    
    // API should be called twice since there's no caching
    verify(() => mockApiService.getAndDecode<DashboardData>(
      '/api/dashboard',
      any(),
    )).called(2);
    
    expect(provider.dashboardData, equals(dashboardData));
  });
  
  test('refreshDashboardData fetches fresh data', () async {
    final dashboardData = DashboardData(
      totalProperties: 10,
      occupiedProperties: 8,
      occupancyRate: 80.0,
      // ... other properties
    );
    
    when(() => mockApiService.getAndDecode<DashboardData>(
      any(),
      any(),
    )).thenAnswer((_) async => dashboardData);
    
    // Load initial data
    await provider.loadDashboardData();
    
    // Refresh should fetch new data
    await provider.refreshDashboardData();
    
    // Verify the data was refreshed
    expect(provider.dashboardData, equals(dashboardData));
  });
}
```

This documentation ensures consistent implementation of the dashboard feature and provides a solid foundation for future development.
