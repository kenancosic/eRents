namespace eRents.Shared.Enums
{
    /// <summary>
    /// Enum for property status values, matching the database PropertyStatus table.
    /// </summary>
    public enum PropertyStatusEnum
    {
        Available = 1,
        Rented = 2,
        UnderMaintenance = 3,
        Unavailable = 4
    }
} 