namespace eRents.Domain.Models.Enums
{
    /// <summary>
    /// Enum for booking status values, matching the database BookingStatus table.
    /// </summary>
    public enum BookingStatusEnum
    {
        Pending = 1,
        Confirmed = 2,
        Cancelled = 3,
        Completed = 4,
        Failed = 5,
        Upcoming = 6,
        Active = 7
    }
} 