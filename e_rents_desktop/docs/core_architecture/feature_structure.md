# eRents Desktop Application Feature Structure Documentation

## Overview

This document provides documentation for the feature structure of the eRents desktop application. The application follows a modular, feature-first architecture where each major domain area is organized into its own feature directory containing all related components, providers, screens, and widgets.

## Feature Organization

The features are organized in the `lib/features/` directory with each feature having its own subdirectory containing all related code:

```
lib/features/
├── auth/
├── chat/
├── home/
├── maintenance/
├── profile/
├── properties/
├── rents/
└── reports/
```

## Feature Details

### 1. Authentication (auth)

Handles user authentication and authorization flows:

- **Login/Logout** functionality
- **Registration** workflows
- **Password reset** mechanisms
- **Token management** and validation
- **Session handling**

Key components:
- AuthProvider for state management
- Login/Register screens
- Authentication guards
- Secure token storage integration

### 2. Chat (chat)

Manages real-time communication features:

- **Message exchange** between users
- **Conversation management**
- **Notification handling** for new messages
- **Message history** retrieval
- **Real-time updates** via WebSocket/SignalR

Key components:
- ChatProvider for message state
- Message models and parsing
- UI components for chat interface
- Real-time communication services

### 3. Home (home)

Provides the main dashboard and overview functionality:

- **Dashboard widgets** and summaries
- **Quick access** to common features
- **Recent activity** tracking
- **Statistics and metrics** display
- **Navigation hub** to other features

Key components:
- HomeProvider for dashboard data
- Dashboard widgets
- Summary cards and charts
- Navigation shortcuts

### 4. Maintenance (maintenance)

Manages property maintenance workflows:

- **Maintenance issue tracking**
- **Work order management**
- **Service provider coordination**
- **Status updates** and notifications
- **Cost tracking** and reporting

Key components:
- MaintenanceProvider for issue state
- Maintenance models and enums
- Issue creation and update workflows
- Status tracking UI components

### 5. Profile (profile)

Handles user profile management:

- **User profile viewing** and editing
- **Account settings** management
- **Preference configuration**
- **Security settings** (password change)
- **Notification preferences**

Key components:
- ProfileProvider for user data
- Profile editing forms
- Settings management
- Avatar and image handling

### 6. Properties (properties)

Core feature for property management:

- **Property listing** and search
- **Property details** viewing
- **Property creation** and editing
- **Image management** for properties
- **Amenity configuration**
- **Status tracking** and filtering

Key components:
- PropertyProvider for property state
- PropertyFormProvider for form handling
- Property models and validation
- CRUD templates integration
- DesktopDataTable for property lists

### 7. Rents (rents)

Manages rental agreements and payments:

- **Rental contract management**
- **Payment tracking** and history
- **Due date monitoring**
- **Late payment handling**
- **Contract renewal** workflows

Key components:
- RentProvider for rental data
- Payment models and tracking
- Contract management workflows
- Financial reporting integration

### 8. Reports (reports)

Provides analytical and reporting capabilities:

- **Financial reports** and summaries
- **Occupancy tracking**
- **Performance metrics**
- **Export functionality**
- **Custom report generation**

Key components:
- ReportsProvider for report data
- Charting and visualization widgets
- Data export services
- Report filtering and customization

## Feature Architecture Patterns

Each feature follows consistent architectural patterns:

### Directory Structure

```
feature_name/
├── providers/        # Feature-specific providers
├── screens/          # Feature screens and pages
├── widgets/          # Feature-specific UI components
├── models/           # Feature data models
├── services/         # Feature-specific services
├── utils/            # Feature utilities
└── constants.dart    # Feature constants
```

### Provider Integration

Features integrate with global providers while maintaining local state:

```dart
// Feature provider extending BaseProvider
class FeatureProvider extends BaseProvider {
  final ApiService _apiService;
  final LookupService _lookupService;
  
  // Feature-specific state and methods
}
```

### Screen Organization

Screens follow consistent naming and structure:

```dart
// Feature screens
- feature_list_screen.dart      // List view
- feature_detail_screen.dart    // Detail view
- feature_form_screen.dart      // Create/edit form
- feature_dashboard_screen.dart // Dashboard/overview
```

### Widget Reusability

Feature widgets follow reusability principles:

```dart
// Feature-specific widgets
- feature_card.dart        // Data display card
- feature_form.dart        // Form component
- feature_filter.dart      // Filtering controls
- feature_summary.dart     // Summary display
```

## Cross-Feature Integration

Features integrate through shared components:

### Global Providers

All features have access to global providers:
- NavigationStateProvider
- PreferencesStateProvider
- AppErrorProvider
- LookupProvider

### Shared Services

Features use shared services:
- ApiService for HTTP requests
- ImageService for image handling
- SecureStorageService for secure data
- UserPreferencesService for settings

### Common Widgets

Features utilize common UI components:
- CRUD templates (ListScreen, FormScreen, DetailScreen)
- DesktopDataTable for data display
- Common input components
- Shared button and card widgets

## Feature Dependencies

Features may depend on other features or shared components:

### Direct Dependencies

- Properties feature depends on Lookup data for property types
- Maintenance feature depends on Properties for issue tracking
- Rents feature depends on Properties and Tenants
- Reports feature depends on multiple features for data

### Service Dependencies

- All features depend on ApiService for data
- Auth-dependent features use authentication services
- Image-dependent features use ImageService
- Lookup-dependent features use LookupService

## Feature Development Guidelines

### New Feature Creation

1. **Create feature directory** in `lib/features/`
2. **Follow standard structure** (providers, screens, widgets)
3. **Extend BaseProvider** for state management
4. **Use shared components** where possible
5. **Implement proper error handling**
6. **Add caching where appropriate**
7. **Create comprehensive documentation**

### Feature Integration

1. **Register providers** in main.dart
2. **Add routes** in routing configuration
3. **Integrate with global state**
4. **Ensure proper navigation**
5. **Test cross-feature interactions**
6. **Document integration points**

## Best Practices

1. **Modularity**: Keep features self-contained
2. **Reusability**: Share components across features
3. **Consistency**: Follow established patterns
4. **Performance**: Implement caching and lazy loading
5. **Security**: Proper authentication and authorization
6. **Testing**: Comprehensive feature testing
7. **Documentation**: Maintain feature documentation
8. **Scalability**: Design for future expansion

## Future Feature Considerations

1. **Notifications**: Centralized notification system
2. **Analytics**: Enhanced analytics and tracking
3. **Document Management**: File and document handling
4. **Calendar Integration**: Scheduling and event management
5. **Mobile Sync**: Cross-platform data synchronization
6. **AI Assistant**: Intelligent property management
7. **Market Analysis**: Real estate market insights
8. **Integration Hub**: Third-party service integration

This feature structure documentation ensures consistent implementation of new features and provides a solid foundation for understanding the application's modular architecture.
