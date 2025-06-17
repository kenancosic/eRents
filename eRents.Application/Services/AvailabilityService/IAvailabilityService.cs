using eRents.Shared.DTO.Response;
using eRents.Shared.Enums;

namespace eRents.Application.Services.AvailabilityService
{
    /// <summary>
    /// Centralized service for all property availability checking logic
    /// Part of Phase 2 refactoring to eliminate duplicated availability logic
    /// </summary>
    public interface IAvailabilityService
    {
        /// <summary>
        /// Check if property is available for daily rental during the specified period
        /// Considers conflicts with annual leases and existing daily bookings
        /// </summary>
        Task<bool> IsAvailableForDailyRental(int propertyId, DateOnly startDate, DateOnly endDate);

        /// <summary>
        /// Check if property is available for annual rental during the specified period
        /// Considers conflicts with existing daily bookings and active annual leases
        /// </summary>
        Task<bool> IsAvailableForAnnualRental(int propertyId, DateOnly startDate, DateOnly endDate);

        /// <summary>
        /// Comprehensive availability check with detailed result information
        /// </summary>
        Task<AvailabilityResult> CheckAvailability(int propertyId, DateOnly startDate, DateOnly endDate, RentalType rentalType);

        /// <summary>
        /// Get detailed information about all conflicts for the specified period
        /// </summary>
        Task<List<ConflictInfo>> GetConflicts(int propertyId, DateOnly startDate, DateOnly endDate);

        /// <summary>
        /// Check if property supports the specified rental type
        /// </summary>
        Task<bool> SupportsRentalType(int propertyId, RentalType rentalType);

        /// <summary>
        /// Basic availability check (existing method from BookingRepository)
        /// </summary>
        Task<bool> IsPropertyAvailable(int propertyId, DateOnly startDate, DateOnly endDate);

        /// <summary>
        /// Check for blocked periods in PropertyAvailability table
        /// </summary>
        Task<bool> HasBlockedPeriods(int propertyId, DateOnly startDate, DateOnly endDate);
    }

    /// <summary>
    /// Detailed availability result with conflict information
    /// </summary>
    public class AvailabilityResult
    {
        public bool IsAvailable { get; set; }
        public List<ConflictInfo> Conflicts { get; set; } = new List<ConflictInfo>();
        public string? Reason { get; set; }
        public int PropertyId { get; set; }
        public DateOnly RequestedStartDate { get; set; }
        public DateOnly RequestedEndDate { get; set; }
        public RentalType RequestedRentalType { get; set; }
    }

    /// <summary>
    /// Information about a specific availability conflict
    /// </summary>
    public class ConflictInfo
    {
        public string ConflictType { get; set; } = string.Empty; // "Booking", "Lease", "Blocked", "Maintenance"
        public DateOnly ConflictStartDate { get; set; }
        public DateOnly ConflictEndDate { get; set; }
        public string? Description { get; set; }
        public int? ConflictId { get; set; } // BookingId, TenantId, etc.
    }
} 