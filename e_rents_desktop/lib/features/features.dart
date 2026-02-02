/// Central export file for all feature-related components
/// This simplifies imports throughout the application
library;

// Feature Registry (main entry point)
export 'features_registry.dart';

// Feature Providers (for direct access when needed)
export 'auth/providers/auth_provider.dart';
export 'chat/providers/chat_provider.dart';
export 'home/providers/home_provider.dart';
export 'maintenance/providers/maintenance_provider.dart';
export 'notifications/providers/notification_provider.dart';
export 'profile/providers/profile_provider.dart';
export 'properties/providers/property_provider.dart';
export 'rents/providers/rents_provider.dart';
export 'reports/providers/reports_provider.dart' hide ReportType;
export 'tenants/providers/tenants_provider.dart';

// Feature Screens (main entry points)
export 'auth/login_screen.dart';
export 'auth/signup_screen.dart';
export 'auth/forgot_password_screen.dart';
export 'auth/verification_screen.dart';
export 'auth/create_password_screen.dart';

export 'chat/chat_screen.dart';
export 'home/home_screen.dart';
export 'maintenance/maintenance_screen.dart';
export 'maintenance/maintenance_form_screen.dart';
export 'maintenance/maintenance_issue_details_screen.dart';
export 'notifications/screens/notifications_screen.dart';
export 'profile/profile_screen.dart';
export 'properties/screens/property_list_screen.dart';
export 'properties/screens/property_detail_screen.dart';
export 'properties/screens/property_form_screen.dart';
export 'rents/rents_screen.dart';
export 'reports/reports_screen.dart';
export 'tenants/screens/tenants_list_screen.dart';

// Feature Models (commonly used across features)
export 'reports/models/report_type.dart';

// Feature Widgets (commonly used components)
export 'notifications/widgets/notification_bell_badge.dart';
export 'notifications/widgets/notification_item.dart';
export 'properties/widgets/property_images_grid.dart';