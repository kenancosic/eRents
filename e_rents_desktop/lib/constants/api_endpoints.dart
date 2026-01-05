/// Standardized API endpoint paths
/// All paths MUST start with leading /
class ApiEndpoints {
  // Auth
  static const String auth = '/Auth';
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String forgotPassword = '$auth/forgot-password';
  static const String verify = '$auth/verify';
  static const String resetPassword = '$auth/reset-password';
  
  // Profile
  static const String profile = '/Profile';
  
  // Users
  static const String users = '/Users';
  static const String changePassword = '$users/change-password';
  
  // Properties
  static const String properties = '/Properties';
  
  // Bookings
  static const String bookings = '/Bookings';
  
  // Tenants
  static const String tenants = '/Tenants';
  
  // Maintenance
  static const String maintenanceIssues = '/MaintenanceIssues';
  
  // Lease Extensions
  static const String leaseExtensions = '/LeaseExtensions';
  
  // Reports
  static const String financialReports = '/FinancialReports';
  
  // Payments
  static const String payments = '/payments';
  static const String stripeConnect = '$payments/stripe/connect';
  static const String stripeConnectStatus = '$stripeConnect/status';
  static const String stripeConnectOnboard = '$stripeConnect/onboard';
  static const String stripeConnectDisconnect = '$stripeConnect/disconnect';
  static const String stripeConnectDashboard = '$stripeConnect/dashboard';
  
  // Chat/Messages
  static const String messages = '/Messages';
  static const String chatRooms = '/ChatRooms';
  
  // Images
  static const String images = '/Images';
  
  // Notifications
  static const String notifications = '/Notifications';
  
  // Reviews
  static const String reviews = '/Reviews';
}
