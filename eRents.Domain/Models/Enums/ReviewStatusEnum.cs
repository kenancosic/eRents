namespace eRents.Domain.Models.Enums
{
    /// <summary>
    /// Enum for review status values used throughout the application.
    /// </summary>
    public enum ReviewStatusEnum
    {
        Pending = 1,
        Approved = 2,
        Rejected = 3,
        Hidden = 4,
        Flagged = 5,
        Escalated = 6
    }
} 