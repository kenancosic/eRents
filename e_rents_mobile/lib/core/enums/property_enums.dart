// Centralized property-related enums

enum PropertyRentalType {
  daily, // Short-term daily rentals (hotels, vacation rentals)
  monthly // Long-term monthly leases with minimum stays
}

// Aligned with backend eRents.Domain.Models.Enums.PropertyTypeEnum
// Backend values: Apartment=1, House=2, Studio=3, Villa=4, Room=5
// We keep condo/townhouse for forward-compat; they may not be sent by backend now.
enum PropertyType { apartment, house, studio, villa, room, condo, townhouse }

// Backend PropertyStatusEnum: Available=1, Occupied=2, UnderMaintenance=3, Unavailable=4
// We map Occupied->rented, UnderMaintenance->maintenance
enum PropertyStatus { available, rented, maintenance, unavailable }
