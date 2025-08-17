// Centralized keys for all lookup categories across the desktop app
// Widgets/providers should refer to these keys instead of hardcoding paths

enum LookupKey {
  // Property-related
  propertyType,
  rentingType,
  propertyStatus,
  amenity,

  // User/booking-related
  userType,
  bookingStatus,

  // Maintenance-related
  maintenanceIssuePriority,
  maintenanceIssueStatus,

  // Misc
  currency,
}
