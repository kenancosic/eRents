namespace eRents.Domain.Models.Enums
{
    /// <summary>
    /// Enum for booking status values, replacing the BookingStatus table.
    /// Matches the seeded values in ERentsContext.
    /// </summary>
    public enum BookingStatusEnum
    {
        Upcoming = 1,
        Completed = 2,
        Cancelled = 3,
        Active = 4,
        Pending = 5,   // Awaiting owner approval (for monthly rentals)
        Approved = 6   // Owner has approved the booking (transitions to Upcoming/Active)
    }
} 